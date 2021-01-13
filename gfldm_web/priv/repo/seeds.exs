# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GfldmWeb.Repo.insert!(%GfldmWeb.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
use Bitwise

{:ok, player} = GfldmWeb.Players.create_player(%{steamid: "[U:1:24408691]"})
{:ok, pattern} = GfldmWeb.Tags.create_tag_pattern(%{name: "Pride", pattern: "e40303;ff8c00;ffed00;008026;004dff;750787", admin_flags: 1 <<< 14})
{:ok, tag} = GfldmWeb.Tags.create_tag(%{name: "Dreae", tag: "Dr.eae", default_pattern: pattern.id})
{:ok, _} = GfldmWeb.Tags.create_player_tag(%{player_id: player.id, tag_id: tag.id})
