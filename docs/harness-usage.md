# Local GLM and DeepSeek usage

Both are enabled in the installed Quotatank widget.

DeepSeek uses an explicitly configured API key first. Otherwise it reads the
official platform grant from `~/.dsh/.credentials.yaml` and makes a read-only
balance request every normal widget refresh (currently five minutes). It totals
normal and bonus wallets within each currency, showing a funded USD wallet
first, otherwise CNY. It never converts or adds different currencies.

GLM reads ZCode's last successful balance API response from the last two dated
logs in `~/.zcode/v2/logs/`, bounded to the final 2 MiB per file. The model meters
show remaining tokens per allowance. The notice preserves the original check
time and flags snapshots older than 15 minutes. Open **Usage Stats in ZCode**
to obtain a newer response, then refresh Quotatank. This source does not poll
Z.ai independently and does not read ZCode credentials. Expired allowances are
omitted; missing data is never treated as zero usage. Cached readings are
excluded from new pacing samples. Trial allowances are not labeled as rolling
five-hour or weekly quotas.

These balance sources affect the Limits view; they do not add token transcripts
to the Tokens view. In Tokens, **All** shows the combined transcript total for
the selected period. Selecting Claude or another provider filters both the
summary row and daily trend to that provider. The All tile shows the combined
token total so the scope remains visible when switching providers.

The integration is a local customization; a plugin update can overwrite it.
The original files and shell settings are backed up under
`~/.config/omarchy/backups/agent-usage-20261024-164942/`.
