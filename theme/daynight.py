#!/usr/bin/env python3
# Prints "<GrokDay|GrokNight> <seconds>" from KDE's NightTime schedule.
# Breakpoints match lookandfeelautoswitcher: midpoint of morning, midpoint of evening.
import re
import subprocess
import sys
import time

BUSCTL = "/usr/bin/busctl"
MAX_WAIT = 3600


def days_from_busctl(text):
    match = re.search(r"a\(xxxxx\)\s+(\d+)\s+(.*)$", text, re.S)
    if not match:
        raise ValueError("no dynamic schedule in NightTime reply")
    count = int(match.group(1))
    nums = [int(n) for n in re.findall(r"\d+", match.group(2))]
    nums = nums[: count * 5]
    if len(nums) != count * 5:
        raise ValueError("truncated NightTime schedule")
    return [tuple(nums[i : i + 5]) for i in range(0, len(nums), 5)]


def pick(now_ms, days):
    events = []
    for _noon, morning_start, morning_end, evening_start, evening_end in days:
        events.append(((morning_start + morning_end) // 2, "GrokDay"))
        events.append(((evening_start + evening_end) // 2, "GrokNight"))
    events.sort()
    scheme = "GrokNight"
    next_ms = None
    for when, name in events:
        if when <= now_ms:
            scheme = name
        elif next_ms is None:
            next_ms = when
            break
    if next_ms is None:
        wait = MAX_WAIT
    else:
        wait = max(1, min(MAX_WAIT, (next_ms - now_ms + 999) // 1000))
    return scheme, wait


def subscribe_days():
    out = subprocess.check_output(
        [
            BUSCTL,
            "--user",
            "call",
            "org.kde.NightTime",
            "/org/kde/NightTime/Manager",
            "org.kde.NightTime.Manager",
            "Subscribe",
            "a{sv}",
            "0",
        ],
        text=True,
    )
    cookie = re.search(r'"Cookie"\s+u\s+(\d+)', out)
    try:
        return days_from_busctl(out)
    finally:
        if cookie:
            subprocess.run(
                [
                    BUSCTL,
                    "--user",
                    "call",
                    "org.kde.NightTime",
                    "/org/kde/NightTime/Manager",
                    "org.kde.NightTime.Manager",
                    "Unsubscribe",
                    "u",
                    cookie.group(1),
                ],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


def self_test():
    days = [
        (1789398626000, 1789375803000, 1789377188000, 1789420063000, 1789421448000),
        (1789485004000, 1789462137000, 1789463521000, 1789506487000, 1789507872000),
    ]
    cases = [
        (1789455600000, "GrokNight"),
        (1789462828000, "GrokNight"),
        (1789462829000, "GrokDay"),
        (1789477200000, "GrokDay"),
        (1789507179000, "GrokDay"),
        (1789507180000, "GrokNight"),
        (1789509600000, "GrokNight"),
    ]
    for now_ms, want in cases:
        got, _wait = pick(now_ms, days)
        if got != want:
            raise SystemExit(f"pick({now_ms})={got} want {want}")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
        sys.exit(0)
    scheme, wait = pick(int(time.time() * 1000), subscribe_days())
    print(f"{scheme} {wait}")
