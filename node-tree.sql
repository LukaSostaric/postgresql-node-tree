/*
 *	Copyright (C) 2010 Luka Sostaric. PostgreSQL Node Tree is
 *	distributed under the terms of the GNU General Public
 *	License.
 *
 *	This program is free software: You can redistribute and/or modify
 *	it under the terms of the GNU General Public License, as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 *	Program Information
 *	-------------------
 *	Program Name: PostgreSQL Node Tree
 *	Module Name: Node Tree
 *	External Components Used: None
 *	Required Modules: None
 *	License: GNU GPL
 *
 *	Author Information
 *	------------------
 *	Full Name: Luka Sostaric
 *	E-mail: <luka@lukasostaric.com>
 *	Website: <http://lukasostaric.com>
 */
drop function insert_node(text, text, integer);
create function insert_node(_name text, _description text, _slug text, _parent_id integer)
returns void as $$
declare rowcount integer;
	lft integer;
	rgt integer;
	maxlft integer;
	maxrgt integer;
	subjectlft integer;
	subjectrgt integer;
	childrencount integer;
begin
	select count(*) into rowcount from nodetree;
	if rowcount = 0 then
		insert into nodetree(name, description, slug, xleft, xright)
		values(_name, _description, _slug, 1, 2);
	else
		if _parent_id is null then
			select max(xright) + 1, max(xright) + 2 into lft, rgt from nodetree;
			insert into nodetree(name, description, slug, xleft, xright)
			values(_name, _description, _slug, lft, rgt);
		else
			select xleft, xright into subjectlft, subjectrgt from nodetree
			where id = _parent_id;
			select count(*) into childrencount from nodetree
				where xleft > subjectlft and xright < subjectrgt;
			if childrencount = 0 then
				update nodetree set xright = xright + 2 where xright >= subjectrgt;
				update nodetree set xleft = xleft + 2 where xleft > subjectlft;
				insert into nodetree(name, description, slug, xleft, xright)
				values(_name, _description, _slug, subjectlft + 1, subjectlft + 2);
			else
				select max(xleft), max(xright) into maxlft, maxrgt
				from nodetree
				where xleft > subjectlft and xright < subjectrgt;
				update nodetree set xleft = xleft + 2 where xleft > maxlft;
				update nodetree set xright = xright + 2 where xright > maxrgt;
				insert into nodetree(name, description, slug, xleft, xright)
				values(_name, _description, _slug, maxlft + 2, maxrgt + 2);
			end if;
		end if;
	end if;
end; $$
language plpgsql;
drop function delete_node(integer);
create function delete_node(_id integer) returns void as $$
begin
	select xleft, xright into subjectlft, subjectrgt from nodetree where id = _id;
	delete from nodetree where xleft >= subjectlft and xright <= subjectrgt;
	x := subjectrgt - subjectlft + 1;
	update nodetree set xleft = xleft - x where xleft > subjectlft;
	update nodetree set xright = xright - x where xright > subjectrgt;
end; $$
language plpgsql;
