defmodule GfldmWeb.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias GfldmWeb.Repo

  alias GfldmWeb.Tags.TagPattern

  @doc """
  Returns the list of gfldm_tag_patterns.

  ## Examples

      iex> list_gfldm_tag_patterns()
      [%TagPattern{}, ...]

  """
  def list_gfldm_tag_pattern do
    Repo.all(TagPattern)
  end

  @doc """
  Gets a single tag_patterns.

  Raises `Ecto.NoResultsError` if the Tag patterns does not exist.

  ## Examples

      iex> get_tag_patterns!(123)
      %TagPattern{}

      iex> get_tag_patterns!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag_pattern!(id), do: Repo.get!(TagPattern, id)

  @doc """
  Creates a tag_patterns.

  ## Examples

      iex> create_tag_patterns(%{field: value})
      {:ok, %TagPattern{}}

      iex> create_tag_patterns(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag_pattern(attrs \\ %{}) do
    %TagPattern{}
    |> TagPattern.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag_patterns.

  ## Examples

      iex> update_tag_patterns(tag_patterns, %{field: new_value})
      {:ok, %TagPattern{}}

      iex> update_tag_patterns(tag_patterns, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag_pattern(%TagPattern{} = tag_patterns, attrs) do
    tag_patterns
    |> TagPattern.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag_patterns.

  ## Examples

      iex> delete_tag_patterns(tag_patterns)
      {:ok, %TagPattern{}}

      iex> delete_tag_patterns(tag_patterns)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag_pattern(%TagPattern{} = tag_patterns) do
    Repo.delete(tag_patterns)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag_patterns changes.

  ## Examples

      iex> change_tag_patterns(tag_patterns)
      %Ecto.Changeset{data: %TagPattern{}}

  """
  def change_tag_pattern(%TagPattern{} = tag_patterns, attrs \\ %{}) do
    TagPattern.changeset(tag_patterns, attrs)
  end

  def get_admin_pattern(admin_flags) do
    Repo.all(from p in TagPattern, where: fragment("? & ?", p.admin_flags, ^admin_flags) != 0)
  end

  alias GfldmWeb.Tags.Tag

  @doc """
  Returns the list of gfldm_tags.

  ## Examples

      iex> list_gfldm_tags()
      [%Tag{}, ...]

  """
  def list_gfldm_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def get_admin_tags(admin_flags) do
    Repo.all(from t in Tag, where: fragment("? & ?", t.admin_flags, ^admin_flags) != 0)
  end

  alias GfldmWeb.Tags.PlayerTag

  @doc """
  Returns the list of gfldm_player_tags.

  ## Examples

      iex> list_gfldm_player_tags()
      [%PlayerTag{}, ...]

  """
  def list_gfldm_player_tags do
    Repo.all(PlayerTag)
  end

  @doc """
  Gets a single player_tag.

  Raises `Ecto.NoResultsError` if the Player tag does not exist.

  ## Examples

      iex> get_player_tag!(123)
      %PlayerTag{}

      iex> get_player_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player_tag!(id), do: Repo.get!(PlayerTag, id)

  @doc """
  Creates a player_tag.

  ## Examples

      iex> create_player_tag(%{field: value})
      {:ok, %PlayerTag{}}

      iex> create_player_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player_tag(attrs \\ %{}) do
    %PlayerTag{}
    |> PlayerTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player_tag.

  ## Examples

      iex> update_player_tag(player_tag, %{field: new_value})
      {:ok, %PlayerTag{}}

      iex> update_player_tag(player_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player_tag(%PlayerTag{} = player_tag, attrs) do
    player_tag
    |> PlayerTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player_tag.

  ## Examples

      iex> delete_player_tag(player_tag)
      {:ok, %PlayerTag{}}

      iex> delete_player_tag(player_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player_tag(%PlayerTag{} = player_tag) do
    Repo.delete(player_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player_tag changes.

  ## Examples

      iex> change_player_tag(player_tag)
      %Ecto.Changeset{data: %PlayerTag{}}

  """
  def change_player_tag(%PlayerTag{} = player_tag, attrs \\ %{}) do
    PlayerTag.changeset(player_tag, attrs)
  end

  def load_player_tag_config(steamid, server_id) do
    Repo.one(from p in GfldmWeb.Players.Player, where: p.steamid == ^steamid and p.server_id == ^server_id, preload: [tag: [:tag_pattern, :chat_pattern, :name_pattern, [tag: :pattern]]])
  end

  def list_tag_presets(admin_flags) do
    Repo.all(from t in Tag, where: fragment("(? & ?)", t.admin_flags, ^admin_flags) != 0, preload: [:pattern])
  end

  def create_tag_override(attrs \\ %{}) do
    %GfldmWeb.Tags.TagOverride{}
    |> GfldmWeb.Tags.TagOverride.changeset(attrs)
    |> Repo.insert()
  end
end
