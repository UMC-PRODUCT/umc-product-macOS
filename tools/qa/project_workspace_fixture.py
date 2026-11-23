#  project_workspace_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic matching application cards for the loopback session fixture."""


def application_cards(member_id, query):
    if member_id != "101" or query.get("gisuId") != ["10"]:
        return []
    # A manual assignment appears only in the unfiltered response.
    if query.get("status"):
        return []
    return [{
        "applicationId": None,
        "projectId": "1",
        "project": {"name": "모아", "thumbnailImageUrl": None,
                    "productOwner": None, "partQuotas": []},
        "matchingRound": {"id": None, "type": "PLAN_DEVELOPER", "phase": "RANDOM_MATCHING"},
        "status": "APPROVED",
    }]


def published_teams(query):
    """PROJECT-007 returns a map keyed by requested project ID."""
    requested_ids = {identifier for value in query.get("projectIds", [])
                     for identifier in value.split(",")}
    if "1" not in requested_ids:
        return {}
    return {"1": {
        "projectId": "1", "productOwner": None, "coProductOwners": [],
        "partGroups": [{"part": "WEB", "members": [
            {"memberId": "101", "nickname": "첫 챌린저", "name": None,
             "schoolName": None, "matchedRoundInfo": None}
        ]}],
    }}
