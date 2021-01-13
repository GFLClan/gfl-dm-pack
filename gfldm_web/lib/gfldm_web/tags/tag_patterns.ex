defmodule GfldmWeb.Tags.TagPattern do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_tag_patterns" do
    field :admin_flags, :integer
    field :name, :string
    field :pattern, :string

    timestamps()
  end

  @doc false
  def changeset(tag_patterns, attrs) do
    tag_patterns
    |> cast(attrs, [:admin_flags, :name, :pattern])
    |> validate_required([:name, :pattern])
  end
end
