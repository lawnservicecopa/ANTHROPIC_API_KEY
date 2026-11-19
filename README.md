# Our Sky Path ✨

A polished sky obby for Roblox where every checkpoint unlocks a secret note or photo.
This is idea #4 from *Roblox Game for Her — Ideas & Build Prompts*.

The whole game (course, lighting, checkpoints, reward cards) is generated from code in
`src/`, so the place file stays empty and everything is versioned in git.

## What's in it

| Feature | Where |
| --- | --- |
| Notes, photos, colors, title, difficulty per stage | `src/shared/GameConfig.lua` ⬅ **edit this** |
| Sunset lighting, atmosphere, bloom, volumetric clouds | `src/server/LightingSetup.lua` |
| Procedural course: jumps, sliding platforms, spinner bars, vanishing clouds, laser strips | `src/server/CourseBuilder.lua` |
| Checkpoints, saving progress, "fell off → back to checkpoint" | `src/server/Progress.lua` |
| Laser strips and vanishing platforms | `src/server/Hazards.lua` |
| Reward card, Memories gallery, intro title, finale confetti | `src/client/RewardUI.lua` |
| Bobbing/spinning checkpoint orbs | `src/client/Floaty.lua` |

## Setup (one time)

1. Install **Roblox Studio** and sign in.
2. Install **[Rokit](https://github.com/rojo-rbx/rokit)**, then in this folder run:
   ```sh
   rokit install
   ```
   That installs the exact versions of `rojo`, `selene` and `stylua` from `rokit.toml`.
3. Install the Rojo plugin in Studio: run `rojo plugin install`, or get "Rojo" from the
   Creator Store.
4. In Studio, create a new **Baseplate** place and save it.
5. In the Explorer, select **Lighting** and set **Technology → Future**. Scripts can't
   change this setting, and it makes the biggest visual difference.
6. *(For saving progress while testing)* **Game Settings → Security → Enable Studio Access
   to API Services**. The place has to be published once for this to work.

## Everyday workflow

```sh
rojo serve
```
In Studio, open the **Rojo** plugin tab and click **Connect**. Code in `src/` now syncs
live into Studio. Press **Play** to test. The default baseplate is removed automatically
and the sky course is built when the server starts.

Before committing:
```sh
stylua src        # format
selene src        # lint
```

## Personalizing it

Everything she'll see lives in `src/shared/GameConfig.lua`:

- **`Stages`**: one entry per checkpoint. Each has a `reward` with a `title`, a `note`
  and an optional `image`. Stage 1 is the welcome card at spawn, and the last stage is the
  finale (its letter types out slowly, with confetti).
- **Photos**: upload an image (Studio → *Asset Manager* → Images, or Creator Dashboard →
  Decals), copy the **image** asset ID, and set `image = "rbxassetid://<id>"`. Photos go
  through Roblox moderation, so keep them Roblox-appropriate.
- **`difficulty`** (1–5) controls the section *after* that checkpoint: gap sizes, platform
  width, and which obstacles can appear.
- **`Palette` / `AccentColor`**: platform and glow colors.
- **`Seed`**: change it to reshuffle the course layout.
- **`Sounds`**: optional `rbxassetid://` IDs for an unlock chime and background music.
  Use audio from Roblox's library. Uploaded copyrighted songs can get removed.

## Publishing for her

1. **File → Publish to Roblox**.
2. Keep the experience **private** while you build it.
3. When it's ready, add her under Creator Dashboard → your experience →
   **Collaborators/Access**, or make it public and send her the link.

## Ideas for later

- Sky-island hub with a photo wall that fills in as she unlocks cards
- Intro camera fly-over (build prompt #9 in the ideas doc)
- Zone music that crossfades per stage (build prompt #7)
- A "race me" mode with a timer for when you both play
