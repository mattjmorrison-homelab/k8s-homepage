#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template . )"
  export RENDERED
}

@test "renders homepage-config services.yaml with an Ad Reporter entry under Applications" {
  applications=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "homepage-config") | .data["services.yaml"]
  ' - | yq eval '.[] | select(has("Applications")) | .Applications' -)

  ad_reporter=$(echo "$applications" | yq eval '.[] | select(has("Ad Reporter")) | .["Ad Reporter"]' -)
  ad_reporter_href=$(echo "$ad_reporter" | yq eval '.href' -)
  ad_reporter_description=$(echo "$ad_reporter" | yq eval '.description' -)

  [ "$ad_reporter_href" = "https://ad-reporter.morrisons.site" ]
  [ "$ad_reporter_description" = "Report an ad, auto-blocked in Pi-hole" ]
}

@test "places Ad Reporter after HDMI Switch and before GraphQL Router under Applications" {
  applications=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "ConfigMap" and .metadata.name == "homepage-config") | .data["services.yaml"]
  ' - | yq eval '.[] | select(has("Applications")) | .Applications' -)

  names=$(echo "$applications" | yq eval '.[] | keys | .[]' -)

  hdmi_line=$(echo "$names" | grep -n '^HDMI Switch$' | cut -d: -f1)
  ad_reporter_line=$(echo "$names" | grep -n '^Ad Reporter$' | cut -d: -f1)
  graphql_line=$(echo "$names" | grep -n '^GraphQL Router$' | cut -d: -f1)

  [ "$hdmi_line" -lt "$ad_reporter_line" ]
  [ "$ad_reporter_line" -lt "$graphql_line" ]
}
