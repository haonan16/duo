# State Schema Outdated

State file is missing required field: `{{FIELD_NAME}}`

This indicates the session was started with an older version of duo.

**Options:**
1. Cancel the session: `/duo:stop`
2. Update duo plugin to version 1.1.2+
3. Restart with the updated plugin

The session will be terminated as 'unexpected' to preserve state information.

Tip: Cancel the loop with /duo:stop and start a new one.
