defmodule GfldmWeb.Repo.Migrations.CreateGfldmPlayers do
  use Ecto.Migration

  def change do
    create table(:gfldm_players) do
      add :steamid, :string

      timestamps()
    end

    create unique_index(:gfldm_players, [:steamid])
  end
end
