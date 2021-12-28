/* variable.vala
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

/**
 * Represents a variable to be substituted in a template.
 */
class Valdo.Variable : Object, Json.Serializable {
    /**
     * The variable name to substitute
     */
    public string name { get; set; }

    /**
     * A short description of the variable's meaning
     */
    public string summary { get; protected set; default = ""; }

    /**
     * The variable's default value, or `null`
     */
    public Value? @default { get; protected set; default = null; }

    /**
     * The pattern that the string must match, or `null` if any string is
     * accepted.
     */
    public string? pattern { get; protected set; default = null; }

    public bool auto { get; protected set; default = false; }

    /**
     * Creates a new variable for substitutions.
     *
     * @param name      the variable name
     * @param summary   a short description of the variable's meaning
     * @param default   the default value, or `null`
     * @param pattern   the pattern that the string must match
     */
    public Variable (string name, string summary, string? default = null, string? pattern = null) {
        this.name = name;
        this.summary = summary;
        if (default != null)
            this.default = new Value (/* FIXME: non-null */(!)default);
        this.pattern = pattern;
    }

    public override bool deserialize_property (string           property_name,
                                               out GLib.Value   value,
                                               ParamSpec        pspec,
                                               Json.Node        node) {
        switch (property_name) {
        case "default":
            var default_value = node.get_string ();
            if (default_value == null) {
                value = "";
                warning ("can't deserealize property '%s' from template file", property_name);
                return false;
            }
            value = new Valdo.Value ((!) default_value);
            return true;
        case "summary":
        case "pattern":
        case "auto":
        default:
            return default_deserialize_property (property_name, out value, pspec, node);
        }
    }
}
