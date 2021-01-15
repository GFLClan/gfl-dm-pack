defmodule GfldmWeb.Repo.Migrations.AddCustomTags do
  use Ecto.Migration

  def change do
    alter table(:gfldm_player_tags) do
      add :custom_tag, :string
    end
  end
end
