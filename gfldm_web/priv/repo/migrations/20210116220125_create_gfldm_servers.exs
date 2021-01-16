defmodule GfldmWeb.Repo.Migrations.CreateGfldmServers do
  use Ecto.Migration

  def change do
    create table(:gfldm_servers) do
      add :name, :string
      add :api_key, :string

      timestamps()
    end

  end
end
