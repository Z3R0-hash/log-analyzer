# SSH Failed Login Analyzer

A small Bash script that reads SSH log files, counts failed login attempts per IP, and flags anything that looks like a brute-force attempt.

## What it does

Point it at a log file (like `/var/log/auth.log`) and it will:
- Pull out every failed SSH login attempt
- Group them by source IP
- Count how many times each IP failed
- Warn you if any IP crosses a threshold (default: 5 attempts)
- Print a clean report, worst offenders first

## Usage

```bash
chmod +x log_analyzer.sh
sudo ./log_analyzer.sh /var/log/auth.log
```

You need `sudo` here because `auth.log` is root-only on most systems.

## Example output

```
Failed login attempts by IP:
-----------------------------
127.0.0.1 : 10 attempts
  ^ WARNING: possible brute force
```

## Backstory

I built this to practice Bash and log analysis for SOC work. It looked simple going in, but I ran into two bugs along the way that taught me more than the script itself did:

**The log format isn't fixed.** My Kali box doesn't ship with a traditional syslog setup out of the box — I had to install `rsyslog` myself to get the classic `/var/log/auth.log` file at all. Before that, I was pulling logs from `journalctl` instead. The two formats aren't the same: the timestamp changes shape between them, which shifts where every other piece of data sits in the line. The field number this script uses to grab the IP only works for one specific format — it's not something you can assume will hold everywhere.

**The script kept matching itself.** While testing, my search for "Failed password" was also picking up `sudo`'s own command logs — because every `sudo` command gets logged verbatim, and my test commands literally contained the words I was searching for. The count kept going up every time I re-ran the test, which was confusing until I realized what was happening. Making the search phrase more specific didn't help, since the new, longer phrase just showed up in the next log entry too. The real fix was to stop matching on the message text altogether and match on something structural instead — the `sshd-session[1234]:` pattern that only real SSH log lines have, and that a typed command would never accidentally produce.

## Limitations, honestly

- The threshold (5 failed attempts) is hardcoded, and it's not based on any password-strength math — it's just meant to separate normal typos from automated hammering. The right number really depends on the environment, and tuning it properly needs real traffic data I don't have on a lab VM.
- This only works correctly with the log format I tested against (rsyslog on Kali). Point it at a different system's logs and the field positions might be wrong.
- It treats every failure the same, regardless of timing — 10 failed logins spread across a week looks identical to 10 in one minute right now, which isn't ideal.
- No support for rotated/compressed logs (`auth.log.1.gz` and similar).

## Requirements

- Bash
- A readable SSH log file (built and tested against rsyslog's auth.log format)
