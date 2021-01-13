defmodule GfldmWeb.Repo.Migrations.CreateGfldmPlayerTags do
  use Ecto.Migration

  def change do
    create table(:gfldm_player_tags) do
      add :tag_color, :string
      add :player_id, references(:gfldm_players, on_delete: :nothing)
      add :tag_id, references(:gfldm_tags, on_delete: :nothing)
      add :tag_pattern_id, references(:gfldm_tag_patterns, on_delete: :nothing)
      add :name_color, :string
      add :name_pattern_id, references(:gfldm_tag_patterns, on_delete: :nothing)
      add :chat_color, :string
      add :chat_pattern_id, references(:gfldm_tag_patterns, on_delete: :nothing)

      timestamps()
    end

    create index(:gfldm_player_tags, [:player_id])
    create index(:gfldm_player_tags, [:tag_id])
    create index(:gfldm_player_tags, [:tag_pattern_id])
    create index(:gfldm_player_tags, [:name_pattern_id])
    create index(:gfldm_player_tags, [:chat_pattern_id])
  end
end
