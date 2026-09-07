#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template . )"
  export RENDERED
}

@test "renders homepage-config bookmarks.yaml with an Open PRs entry under External" {
  bookmarks=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "homepage-config") | .data["bookmarks.yaml"]
  ' -)

  open_prs=$(echo "$bookmarks" | yq eval '
    .[] | select(has("External")) | .External[] | select(has("Open PRs")) | .["Open PRs"][0]
  ' -)
  open_prs_href=$(echo "$open_prs" | yq eval '.href' -)
  open_prs_description=$(echo "$open_prs" | yq eval '.description' -)

  [ "$open_prs_href" = "https://github.com/pulls?q=is%3Aopen+is%3Apr+org%3Amattjmorrison-homelab" ]
  [ "$open_prs_description" = "All open pull requests across the org" ]
}

@test "does not render a Woodpecker services entry" {
  services=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "homepage-config") | .data["services.yaml"]
  ' -)

  woodpecker=$(echo "$services" | yq eval '.[] | select(has("Infrastructure")) | .Infrastructure[] | select(has("Woodpecker"))' -)

  [ -z "$woodpecker" ]
}
