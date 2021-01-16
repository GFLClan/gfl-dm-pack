defmodule GfldmWeb.Repo.Migrations.CreateTagOverrides do
  use Ecto.Migration

  def change do
    create table(:tag_overrides) do
      add :tag_id, references(:gfldm_tags, on_delete: :nothing)
      add :player_id, references(:gfldm_players, on_delete: :nothing)

      timestamps()
    end

    create index(:tag_overrides, [:tag_id])
    create index(:tag_overrides, [:player_id])
  end
end
