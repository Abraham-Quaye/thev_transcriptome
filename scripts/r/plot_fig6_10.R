#!/usr/bin/env Rscript

library(flextable)
source("scripts/r/abundance_analyses.R")
source("scripts/r/reg_by_reg_plots.R")

# plot the transcript breakdown for each TU

# function to plot figures
plot_figs <- function(trxpt_table, trxpt_plot){
  
  df_name <- deparse(substitute(trxpt_table))
  t_fnt <- 12
  t_width <- ifelse(df_name == "reg_mlp_brkdown", 0.1, 0.6)
  t_id_width <- ifelse(df_name == "reg_mlp_brkdown", 2, 1.2)
  
  set_flextable_defaults(font.size = t_fnt)

  # prepare junction table
  junc_tab <- trxpt_table %>%
    flextable(.,
            col_keys = c("trxpt_id", "start", "end", "intron_len",
                         "strand", "4hpi", "12hpi", "24hpi", "72hpi",
                         "status")) %>%
    theme_zebra() %>%
    flextable::set_table_properties(layout = "fixed",
                                    opts_pdf = list(caption_repeat = F)) %>%
    flextable::set_header_labels(start = "Start", end = "End",
                                 strand = "Strand", trxpt_id = "Transcript ID",
                                 intron_len = "Intron Length", "4hpi" = "4h.p.i",
                                 "12hpi" = "12h.p.i", "24hpi" = "24h.p.i",
                                 "72hpi" = "72h.p.i", "status" = "Junction Status") %>%
    flextable::align(align = "center", part = "all") %>%
    add_header_row(., values = c("", "Splice Junction", "", "Junction Reads", ""),
                   colwidths = c(1, 3, 1, 4, 1)) %>%
    flextable::vline(j = c(1, 4, 5, 9),
                     border = fp_border_default(color = "grey", width = 1.5)) %>%
    flextable::font(part = "all", fontname = "Arial") %>%
    flextable::width(width = t_width) %>%
    flextable::width(width = t_id_width, j = "trxpt_id") %>%
    flextable::fontsize(size = t_fnt, part = "all")

  if ("TRXPT_1, TRXPT_4" %in% pull(trxpt_table, trxpt_id)){
    junc_tab <- junc_tab %>%
    footnote(., i = 1, j = 10, value = as_paragraph(c("Not validated for TRXPT_4")),
             ref_symbols = c("*"), part = "body")
  }
  
  # combine with trxpt plot
  return(trxpt_plot / plot_spacer()/ gen_grob(junc_tab, fit = "auto", scaling = F))
}

# Figure 6
fig6 <- plot_figs(reg_e1_brkdown, brkdwn_e1_trxtps) +
  plot_layout(heights = c(2.5, 0.05, 2)) 

# Figure 7
fig7 <- plot_figs(reg_e2_brkdown, brkdwn_e2_trxtps) +
  plot_layout(heights = c(1, 0.05, 1))

# Figure 8
fig8 <- plot_figs(reg_e3_brkdown, brkdwn_e3_trxtps) +
  plot_layout(heights = c(1.5, 0.05, 1))

# Figure 9
reg_e4_brkdown <- reg_e4_brkdown %>%
  mutate(splice_site = "GT-AG",
         `4hpi` = as.numeric(`4hpi`), `12hpi` = as.numeric(`12hpi`),
         `24hpi` = as.numeric(`24hpi`), `72hpi` = as.numeric(`72hpi`)) %>%
  # select(-c(coding_potential, region)) %>%
  group_by(trxpt_id, start, end, splice_site, intron_len, strand, status) %>%
  reframe("4hpi" = sum(`4hpi`),
          "12hpi" = sum(`12hpi`),
          "24hpi" = sum(`24hpi`),
          "72hpi" = sum(`72hpi`)) %>%
  select(trxpt_id, start, end, splice_site, intron_len, strand, "4hpi", "12hpi",
         "24hpi", "72hpi", status)

fig9 <- plot_figs(reg_e4_brkdown, brkdwn_e4_trxtps) +
  plot_layout(heights = c(1 , 0.01, 1))

# Figure 10
fig10 <- plot_figs(reg_mlp_brkdown, brkdwn_mlp_trxtps) +
  plot_layout(heights = c(1, 0.01, 1))

figures <- list(fig6, fig7, fig8)
fig_str <- list("fig6", "fig7", "fig8", "fig10")

for(p in seq_along(figures)){
  num <- parse_number(fig_str[[p]])
  ggsave(plot = figures[[p]],
         filename = paste0("results/r/figures/figure_", num,".png"),
         dpi = 400, width = 18, height = 16)
}

ggsave(plot = fig9,
       filename = "results/r/figures/figure_9.png",
       dpi = 400, width = 8, height = 4)

ggsave(plot = fig10,
       filename = "results/r/figures/figure_10.png",
       dpi = 400, width = 18, height = 18)

