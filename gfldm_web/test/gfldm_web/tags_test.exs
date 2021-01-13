defmodule GfldmWeb.TagsTest do
  use GfldmWeb.DataCase

  alias GfldmWeb.Tags

  describe "gfldm_tag_patterns" do
    alias GfldmWeb.Tags.TagPatterns

    @valid_attrs %{admin_flags: 42, pattern: "some pattern"}
    @update_attrs %{admin_flags: 43, pattern: "some updated pattern"}
    @invalid_attrs %{admin_flags: nil, pattern: nil}

    def tag_patterns_fixture(attrs \\ %{}) do
      {:ok, tag_patterns} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tags.create_tag_patterns()

      tag_patterns
    end

    test "list_gfldm_tag_patterns/0 returns all gfldm_tag_patterns" do
      tag_patterns = tag_patterns_fixture()
      assert Tags.list_gfldm_tag_patterns() == [tag_patterns]
    end

    test "get_tag_patterns!/1 returns the tag_patterns with given id" do
      tag_patterns = tag_patterns_fixture()
      assert Tags.get_tag_patterns!(tag_patterns.id) == tag_patterns
    end

    test "create_tag_patterns/1 with valid data creates a tag_patterns" do
      assert {:ok, %TagPatterns{} = tag_patterns} = Tags.create_tag_patterns(@valid_attrs)
      assert tag_patterns.admin_flags == 42
      assert tag_patterns.pattern == "some pattern"
    end

    test "create_tag_patterns/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tags.create_tag_patterns(@invalid_attrs)
    end

    test "update_tag_patterns/2 with valid data updates the tag_patterns" do
      tag_patterns = tag_patterns_fixture()
      assert {:ok, %TagPatterns{} = tag_patterns} = Tags.update_tag_patterns(tag_patterns, @update_attrs)
      assert tag_patterns.admin_flags == 43
      assert tag_patterns.pattern == "some updated pattern"
    end

    test "update_tag_patterns/2 with invalid data returns error changeset" do
      tag_patterns = tag_patterns_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag_patterns(tag_patterns, @invalid_attrs)
      assert tag_patterns == Tags.get_tag_patterns!(tag_patterns.id)
    end

    test "delete_tag_patterns/1 deletes the tag_patterns" do
      tag_patterns = tag_patterns_fixture()
      assert {:ok, %TagPatterns{}} = Tags.delete_tag_patterns(tag_patterns)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag_patterns!(tag_patterns.id) end
    end

    test "change_tag_patterns/1 returns a tag_patterns changeset" do
      tag_patterns = tag_patterns_fixture()
      assert %Ecto.Changeset{} = Tags.change_tag_patterns(tag_patterns)
    end
  end

  describe "gfldm_tags" do
    alias GfldmWeb.Tags.Tag

    @valid_attrs %{admin_flags: 42, default_color: "some default_color", tag: "some tag"}
    @update_attrs %{admin_flags: 43, default_color: "some updated default_color", tag: "some updated tag"}
    @invalid_attrs %{admin_flags: nil, default_color: nil, tag: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tags.create_tag()

      tag
    end

    test "list_gfldm_tags/0 returns all gfldm_tags" do
      tag = tag_fixture()
      assert Tags.list_gfldm_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Tags.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Tags.create_tag(@valid_attrs)
      assert tag.admin_flags == 42
      assert tag.default_color == "some default_color"
      assert tag.tag == "some tag"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tags.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = Tags.update_tag(tag, @update_attrs)
      assert tag.admin_flags == 43
      assert tag.default_color == "some updated default_color"
      assert tag.tag == "some updated tag"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(tag, @invalid_attrs)
      assert tag == Tags.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Tags.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Tags.change_tag(tag)
    end
  end

  describe "gfldm_player_tags" do
    alias GfldmWeb.Tags.PlayerTag

    @valid_attrs %{tag_color: "some tag_color"}
    @update_attrs %{tag_color: "some updated tag_color"}
    @invalid_attrs %{tag_color: nil}

    def player_tag_fixture(attrs \\ %{}) do
      {:ok, player_tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tags.create_player_tag()

      player_tag
    end

    test "list_gfldm_player_tags/0 returns all gfldm_player_tags" do
      player_tag = player_tag_fixture()
      assert Tags.list_gfldm_player_tags() == [player_tag]
    end

    test "get_player_tag!/1 returns the player_tag with given id" do
      player_tag = player_tag_fixture()
      assert Tags.get_player_tag!(player_tag.id) == player_tag
    end

    test "create_player_tag/1 with valid data creates a player_tag" do
      assert {:ok, %PlayerTag{} = player_tag} = Tags.create_player_tag(@valid_attrs)
      assert player_tag.tag_color == "some tag_color"
    end

    test "create_player_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tags.create_player_tag(@invalid_attrs)
    end

    test "update_player_tag/2 with valid data updates the player_tag" do
      player_tag = player_tag_fixture()
      assert {:ok, %PlayerTag{} = player_tag} = Tags.update_player_tag(player_tag, @update_attrs)
      assert player_tag.tag_color == "some updated tag_color"
    end

    test "update_player_tag/2 with invalid data returns error changeset" do
      player_tag = player_tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.update_player_tag(player_tag, @invalid_attrs)
      assert player_tag == Tags.get_player_tag!(player_tag.id)
    end

    test "delete_player_tag/1 deletes the player_tag" do
      player_tag = player_tag_fixture()
      assert {:ok, %PlayerTag{}} = Tags.delete_player_tag(player_tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_player_tag!(player_tag.id) end
    end

    test "change_player_tag/1 returns a player_tag changeset" do
      player_tag = player_tag_fixture()
      assert %Ecto.Changeset{} = Tags.change_player_tag(player_tag)
    end
  end
end
