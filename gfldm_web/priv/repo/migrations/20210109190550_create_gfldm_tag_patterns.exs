defmodule GfldmWeb.Repo.Migrations.CreateGfldmTagPatterns do
  use Ecto.Migration

  def change do
    create table(:gfldm_tag_patterns) do
      add :admin_flags, :integer
      add :pattern, :string

      timestamps()
    end

  end
end
