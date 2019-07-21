/*
 *  Copyright (C) 2010 Luka Sostaric. PostgreSQL Node Tree is
 *  distributed under the terms of the GNU General Public
 *  License.
 *
 *  This program is free software: You can redistribute and/or modify
 *  it under the terms of the GNU General Public License, as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 *  Program Information
 *  -------------------
 *  Program Name: PostgreSQL Node Tree
 *  Module Name: Node Tree
 *  External Components Used: None
 *  Required Modules: None
 *  License: GNU GPL
 *
 *  Author Information
 *  ------------------
 *  Full Name: Luka Sostaric
 *  E-mail: luka@lukasostaric.com
 *  Website: www.lukasostaric.com
 */
DROP FUNCTION insert_node(text, text, integer);
CREATE FUNCTION insert_node(_name text, _description text, _slug text, _parent_id integer)
RETURNS void AS $$
DECLARE rowcount integer;
    lft integer;
    rgt integer;
    maxlft integer;
    maxrgt integer;
    subjectlft integer;
    subjectrgt integer;
    childrencount integer;
BEGIN
    SELECT count(*) INTO rowcount FROM nodetree;
    IF rowcount = 0 THEN
        INSERT INTO nodetree(name, description, slug, xleft, xright)
            VALUES(_name, _description, _slug, 1, 2);
    ELSE
        IF _parent_id IS NULL THEN
            SELECT max(xright) + 1, max(xright) + 2 INTO lft, rgt FROM nodetree;
            INSERT INTO nodetree(name, description, slug, xleft, xright)
                VALUES(_name, _description, _slug, lft, rgt);
        ELSE
            SELECT xleft, xright INTO subjectlft, subjectrgt FROM nodetree
                WHERE id = _parent_id;
            SELECT count(*) INTO childrencount FROM nodetree
                WHERE xleft > subjectlft AND xright < subjectrgt;
            IF childrencount = 0 THEN
                UPDATE nodetree SET xright = xright + 2 WHERE xright >= subjectrgt;
                UPDATE nodetree SET xleft = xleft + 2 WHERE xleft > subjectlft;
                INSERT INTO nodetree(name, description, slug, xleft, xright)
                    VALUES(_name, _description, _slug, subjectlft + 1, subjectlft + 2);
            ELSE
                SELECT max(xleft), max(xright) INTO maxlft, maxrgt
                    FROM nodetree WHERE xleft > subjectlft
                    AND xright < subjectrgt;
                UPDATE nodetree SET xleft = xleft + 2 WHERE xleft > maxlft;
                UPDATE nodetree SET xright = xright + 2 WHERE xright > maxrgt;
                INSERT INTO nodetree(name, description, slug, xleft, xright)
                    VALUES(_name, _description, _slug, maxlft + 2, maxrgt + 2);
            END IF;
        END IF;
    END IF;
END; $$
LANGUAGE plpgsql;
DROP FUNCTION delete_node(integer);
CREATE FUNCTION delete_node(_id integer) RETURNS void AS $$
BEGIN
    SELECT xleft, xright INTO subjectlft, subjectrgt FROM nodetree WHERE id = _id;
    DELETE FROM nodetree WHERE xleft >= subjectlft AND xright <= subjectrgt;
        x := subjectrgt - subjectlft + 1;
    UPDATE nodetree SET xleft = xleft - x WHERE xleft > subjectlft;
    UPDATE nodetree SET xright = xright - x WHERE xright > subjectrgt;
END; $$
LANGUAGE plpgsql;
