-- Palette values adapted from Herdr v0.9.0, src/app/state.rs (Apache-2.0).
-- https://github.com/herdrdev/herdr/blob/v0.9.0/src/app/state.rs
-- Modified for Pickr: retain the tokens used by its semantic roles, store RGB
-- as hex, and preserve the original Pickr Rosé Pine mapping in themes.lua.
-- See vendor/HERDR-LICENSE for the upstream license.
-- Columns: panel_bg, selection_bg, text, subtext0, overlay0, surface1,
--          accent, red, green, yellow, teal.
return {
  catppuccin = { "#181825", "#313244", "#cdd6f4", "#a6adc8", "#6c7086", "#45475a", "#89b4fa", "#f38ba8", "#a6e3a1", "#f9e2af", "#94e2d5" },
  ["catppuccin-latte"] = { "#eff1f5", "#bdd0f5", "#4c4f69", "#6c6f85", "#9ca0b0", "#bcc0cc", "#1e66f5", "#d20f39", "#40a02b", "#df8e1d", "#179299" },
  terminal = { "default", "darkgray", "default", "gray", "gray", "darkgray", "blue", "lightred", "green", "yellow", "cyan" },
  ["tokyo-night"] = { "#1a1b26", "#2d3650", "#c0caf5", "#a9b1d6", "#565f89", "#414868", "#7aa2f7", "#f7768e", "#9ece6a", "#e0af68", "#7dcfff" },
  ["tokyo-night-day"] = { "#e1e2e7", "#b6cae7", "#3760bf", "#6172b0", "#8990b3", "#a8aecb", "#2e7de9", "#f52a65", "#587539", "#8c6c3e", "#118c74" },
  dracula = { "#282a36", "#463f5d", "#f8f8f2", "#d2d2dc", "#6272a4", "#6272a4", "#bd93f9", "#ff5555", "#50fa7b", "#f1fa8c", "#8be9fd" },
  nord = { "#2e3440", "#40505d", "#eceff4", "#d8dee9", "#4c566a", "#434c5e", "#88c0d0", "#bf616a", "#a3be8c", "#ebcb8b", "#8fbcbb" },
  gruvbox = { "#282828", "#4b3f27", "#ebdbb2", "#d5c4a1", "#928374", "#504945", "#d79921", "#fb4934", "#b8bb26", "#fabd2f", "#8ec07c" },
  ["gruvbox-light"] = { "#fbf1c7", "#ebdbb2", "#3c3836", "#504945", "#928374", "#d5c4a1", "#076678", "#9d0006", "#79740e", "#b57614", "#427b58" },
  ["one-dark"] = { "#282c34", "#334659", "#abb2bf", "#969ca8", "#5c6370", "#3e4451", "#61afef", "#e06c75", "#98c379", "#e5c07b", "#56b6c2" },
  ["one-light"] = { "#fafafa", "#cddbf8", "#383a42", "#686b77", "#a0a1a7", "#e5e5e6", "#4078f2", "#e45649", "#50a14f", "#c18401", "#0184bc" },
  solarized = { "#002b36", "#083e55", "#93a1a1", "#839496", "#586e75", "#586e75", "#268bd2", "#dc322f", "#859900", "#b58900", "#2aa198" },
  ["solarized-light"] = { "#fdf6e3", "#c9dcdf", "#657b83", "#839496", "#93a1a1", "#93a1a1", "#268bd2", "#dc322f", "#859900", "#b58900", "#2aa198" },
  kanagawa = { "#1f1f28", "#32384b", "#dcd7ba", "#c8c3aa", "#727169", "#363646", "#7e9cd8", "#c34043", "#76946a", "#c0a36e", "#7fb4ca" },
  ["kanagawa-lotus"] = { "#f2ecbc", "#dcd5ac", "#545464", "#43436c", "#a09cac", "#c9cbd1", "#4d699b", "#c84053", "#6f894e", "#77713f", "#4e8ca2" },
  ["rose-pine"] = { "#191724", "#3b344b", "#e0def4", "#c8c5dc", "#6e6a86", "#26233a", "#c4a7e7", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8" },
  ["rose-pine-dawn"] = { "#faf4ed", "#f2e9e1", "#464261", "#797593", "#9893a5", "#fffaf3", "#907aa9", "#b4637a", "#286983", "#ea9d34", "#56949f" },
  vesper = { "#1a1a1a", "#232323", "#ffffff", "#a0a0a0", "#5c5c5c", "#282828", "#ffc799", "#ff8080", "#99ffe4", "#ffc799", "#66ddcc" },
}
