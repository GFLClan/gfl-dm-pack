defmodule GfldmWebWeb.ServerTags.TagConfig do
  @derive Jason.Encoder
  defstruct [
    tag: "",
    tag_color: "",
    name_color: "",
    chat_color: "",
    tag_pattern: "",
    name_pattern: "",
    chat_pattern: "",
    default_tag_color: "",
    default_name_color: "",
    default_chat_color: "",
    default_tag_pattern: "",
    default_name_pattern: "",
    default_chat_pattern: "",
    custom_tag: ""
  ]
end
