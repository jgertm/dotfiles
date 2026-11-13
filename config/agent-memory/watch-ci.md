# Watch CI after pushing

Wait for CI on the pushed commit to finish and report the outcome. Choose the GitHub CLI command for the scope you need.

- For all checks on a PR, run `gh pr checks "$pr" --watch`.
- For an Actions workflow run, run `gh run watch "$run_id" --compact --exit-status`. Find the relevant IDs with `gh run list --commit "$sha" --json databaseId,workflowName,event,status,url`, where `sha` is the pushed commit. Retry discovery if GitHub is still registering the expected run.
- For failed steps, run `gh run view "$run_id" --log-failed`.

To return as soon as one Actions job finishes, get its ID with `gh run view "$run_id" --json jobs --jq '.jobs[] | [.databaseId, .name] | @tsv'`. Set `job_id` to that ID and run this from the repository. The subshell returns zero for success and nonzero for any other conclusion.

```sh
(
  while :; do
    conclusion=$(gh api "repos/{owner}/{repo}/actions/jobs/$job_id" \
      --jq 'if .status == "completed" then .conclusion else empty end') || exit "$?"
    if [ -n "$conclusion" ]; then
      printf '%s\n' "$conclusion"
      [ "$conclusion" = success ]
      exit "$?"
    fi
    sleep 10
  done
)
```
