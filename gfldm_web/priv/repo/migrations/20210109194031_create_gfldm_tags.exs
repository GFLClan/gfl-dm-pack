defmodule GfldmWeb.Repo.Migrations.CreateGfldmTags do
  use Ecto.Migration

  def change do
    create table(:gfldm_tags) do
      add :tag, :string
      add :name, :string
      add :default_tag_color, :string
      add :default_name_color, :string
      add :default_chat_color, :string
      add :admin_flags, :integer
      add :default_pattern, references(:gfldm_tag_patterns, on_delete: :nothing)

      timestamps()
    end

    create index(:gfldm_tags, [:default_pattern])
  end
end
