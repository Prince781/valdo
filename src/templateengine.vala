/* templateengine.vala
 *
 * Copyright 2021 Princeton Ferro <princetonferro@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Valdo.TemplateEngine {
    /**
     * Lists all files in a directory recursively.
     */
    public HashTable<FileInfo, File> list_files (File                       dir,
                                                 Cancellable?               cancellable = null,
                                                 HashTable<FileInfo, File>  found = new HashTable<FileInfo, File> (null, null)) throws Error {
        FileEnumerator enumerator = dir.enumerate_children (
            FileAttribute.ID_FILE,
            NOFOLLOW_SYMLINKS,
            cancellable);

        try {
            FileInfo? finfo;
            while ((finfo = enumerator.next_file (cancellable)) != null) {
                if (/* FIXME: non-null */ ((!) finfo).get_file_type () == DIRECTORY) {
                    list_files (
                        enumerator.get_child (/* FIXME: non-null */ (!) finfo),
                        cancellable,
                        found);
                }
                found[(!) finfo] = enumerator.get_child ((!) finfo);
            }
        } catch (Error e) {
            warning ("could not get next file in dir %s", (!) dir.get_path ());
        }

        return found;
    }


    /**
     * Apply the template to the current directory, with the substitutions.
     * A new directory will be created with the project name.
     *
     * @param template      the template to apply
     * @param current_dir   the current directory
     * @param project_name  the new project's name
     * @param substitutions the variable substitutions (variables => their new values)
     */
    void apply_template (Template                   template,
                         File                       current_dir,
                         string                     project_name,
                         HashTable<string, string>  substitutions) throws Error {
        // maps template file to its destination file
        var template_files = new HashTable<File, File> (null, null);

        // create the new project directory
        var project_dir = current_dir.get_child (project_name);
        project_dir.make_directory ();

        // copy everything into it
        var files_list = list_files (template.directory);
        foreach (var template_child_info in files_list.get_keys_as_array ()) {
            var file_type = /* FIXME: non-null */ ((!) template_child_info).get_file_type ();
            if (!(file_type == REGULAR || file_type == SYMBOLIC_LINK ||
                  file_type == SHORTCUT || file_type == DIRECTORY))
                continue;

            var template_child = files_list[template_child_info];
            var template_child_path_relative = (!) template.directory.get_relative_path (template_child);

            if (template_child_path_relative == "template.json")
                continue;   // don't copy over template.json

            // substitute path name
            var project_child_path_relative = /(?<!\$)\${(\w+)}/m
                .replace_eval (template_child_path_relative, template_child_path_relative.length, 0, 0, (match_info, result) => {
                    string variable_name = (!) match_info.fetch (1);

                    if (variable_name in substitutions) {
                        result.append (substitutions[variable_name]);
                    } else {
                        warning ("could not substitute `${%s}` in %s - prepend a `$` if this was intentional",
                                 variable_name, template_child_path_relative);
                        result.append (variable_name);
                    }

                    return false;
                });

            var project_child = project_dir.resolve_relative_path (project_child_path_relative);
            var project_child_parentdir = project_child.get_parent ();

            if (file_type == DIRECTORY) {
                // create an empty directory
                DirUtils.create_with_parents ((!) project_child.get_path (), 0755);
            } else {
                // create the parent directory of the file
                if (project_child_parentdir != null) {
                    DirUtils.create_with_parents ((!) (/* FIXME: non-null */ (!) project_child_parentdir).get_path (), 0755);
                }

                template_files[template_child] = project_child;
            }
        }

        // perform template substitutions
        foreach (var template_file in template_files.get_keys_as_array ()) {
            string template_contents;
            FileUtils.get_contents ((!) template_file.get_path (), out template_contents);

            // substitute variables
            template_contents = /(?<!\$)\${(\w+)}/m
                .replace_eval (template_contents, template_contents.length, 0, 0, (match_info, result) => {
                    string variable_name = (!) match_info.fetch (1);

                    if (variable_name in substitutions) {
                        result.append (substitutions[variable_name].escape ().replace ("'", "\\'"));
                    } else {
                        warning ("could not substitute `${%s}` in %s - prepend a `$` if this was intentional",
                            variable_name, (!) template_file.get_path ());
                        result.append (variable_name);
                    }

                    return false;
                });

            // now write to the new file
            var project_file = template_files[template_file];
            project_file.create (NONE).write_all (template_contents.data, null);
        }

        // finally, initialize the git repository (we don't care if this part fails)
        if (Environment.find_program_in_path ("git") != null) {
            try {
                Process.spawn_sync (
                    project_dir.get_path (),
                    {"git", "init"},
                    Environ.get (),
                    SEARCH_PATH | SEARCH_PATH_FROM_ENVP,
                    null
                );
                // create a new gitignore for meson and c files
                project_dir.get_child (".gitignore").create (NONE).write_all ("build/\n*~".data, null);
            } catch (Error e) {
                warning ("could not initialize a git repository - %s", e.message);
            }
        }
    }
}
