defmodule GfldmWebWeb.ServerTags.TagPreset do
  @derive Jason.Encoder
  defstruct [
    tag: "",
    tag_id: 0,
    tag_color: "",
    name_color: "",
    chat_color: "",
    tag_pattern: "",
    name_pattern: "",
    chat_pattern: ""
  ]

  alias GfldmWeb.Tags.Tag


  def from_tag(%Tag{} = tag) do
    config = %GfldmWebWeb.ServerTags.TagPreset{}
    |> Map.put(:tag, blank?(tag.tag))
    |> Map.put(:tag_color, blank?(tag.default_tag_color))
    |> Map.put(:name_color, blank?(tag.default_name_color))
    |> Map.put(:chat_color, blank?(tag.default_chat_color))
    |> Map.put(:tag_id, tag.id)

    case tag do
      %{pattern: nil} -> config
      %{pattern: pattern} -> Map.put(config, :tag_pattern, pattern.pattern)
    end
  end

  defp blank?(nil), do: ""
  defp blank?(str), do: str
end
