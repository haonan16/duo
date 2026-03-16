# Plan File Modified

The plan file `{{PLAN_FILE}}` has been modified since the session started.

**Modifying plan files is forbidden during an active session.**

If you need to change the plan:
1. Cancel the current session: `/duo:stop`
2. Update the plan file
3. Start a new session: `/duo:run {{PLAN_FILE}}`

Backup available at: `{{BACKUP_PATH}}`

Tip: The plan file is read-only during the loop.
