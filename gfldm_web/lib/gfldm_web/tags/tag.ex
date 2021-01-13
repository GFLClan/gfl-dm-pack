defmodule GfldmWeb.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_tags" do
    field :admin_flags, :integer
    field :default_tag_color, :string
    field :default_name_color, :string
    field :default_chat_color, :string
    field :tag, :string
    field :name, :string
    belongs_to :pattern, GfldmWeb.Tags.TagPattern, foreign_key: :default_pattern

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:tag, :default_tag_color, :default_name_color, :default_chat_color, :name, :admin_flags, :default_pattern])
    |> validate_required([:tag, :name])
  end
end
