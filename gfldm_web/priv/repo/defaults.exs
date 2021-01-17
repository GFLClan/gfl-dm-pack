use Bitwise

{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Admin",
    tag: "Admin",
    admin_flags: 1 <<< 1,
    default_tag_color: "4d7455"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Super Admin",
    tag: "Super Admin",
    admin_flags: 1 <<< 6,
    default_tag_color: "b22222",
    default_name_color: "ffd700"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Root",
    tag: "Root",
    admin_flags: 1 <<< 14,
    default_tag_color: "00bfff",
    default_name_color: "9932cc",
    default_chat_color: "f8f8ff"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Hattrick",
    tag: "Hattrick",
    default_tag_color: "23f0c7"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Headhunter",
    tag: "[Headhunter]",
    default_tag_color: "68c5db",
    default_name_color: "ff5a5f"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "one deag",
    tag: "one deag",
    default_tag_color: "725ac1",
    default_name_color: "0bc9cd",
    default_chat_color: "f7ece1"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Monsterkill",
    tag: "Monsterkill",
    default_tag_color: "f71735"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Unstoppable",
    tag: "Unstoppable",
    default_tag_color: "f71735"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Godlike",
    tag: "Godlike",
    default_tag_color: "f71735",
    default_name_color: "68c5db",
    default_chat_color: "edb4cb"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Wickedsick",
    tag: "Wickedsick",
    default_tag_color: "485696",
    default_name_color: "f24c00",
    default_chat_color: "e7e7e7"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Holyshit",
    tag: "Holyshit",
    default_tag_color: "ff729f",
    default_name_color: "6fd08c",
    default_chat_color: "e6edef"
  }
)

{:ok, pattern} = GfldmWeb.Tags.create_tag_pattern(
  %{
    name: "Scout Elite",
    pattern: "pattern_wings;d64045;5887ff;a682ff;5887ff;d64045"
  }
)
{:ok, _} = GfldmWeb.Tags.create_tag(
  %{
    name: "Scout Elite",
    tag: "-= Scout Elite =-",
    default_name_color: "e75a7c",
    default_chat_color: "e7e7e7",
    default_pattern: pattern.id
  }
)
