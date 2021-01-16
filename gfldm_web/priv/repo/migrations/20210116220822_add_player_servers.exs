defmodule GfldmWeb.Repo.Migrations.AddPlayerServers do
  use Ecto.Migration

  def change do
    alter table(:gfldm_players) do
      add :server_id, references(:gfldm_servers, on_delete: :delete_all)
    end
  end
end
