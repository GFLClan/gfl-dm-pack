defmodule GfldmWeb.Repo.Migrations.CreatePatternName do
  use Ecto.Migration

  def change do
    alter table("gfldm_tag_patterns") do
      add :name, :string
    end
  end
end
