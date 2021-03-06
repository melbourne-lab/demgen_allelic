library(ggplot2)
library(dplyr)
library(tidyr)

rm(list = ls())

all.data = read.csv('simulations/outputs/final_results/alldata_combined.csv')

all.tau = all.data %>%
  group_by(trial, n.pop0, low.var, alpha) %>%
  mutate(loglam = c(NA, diff(log(n))),
         d = abs(2.75 - gbar),
         k = c(NA, exp(diff(log(d)))),
         varred = c(NA, exp(diff(log(v))))) %>%
  mutate(tau = max(gen) - gen + 1 - as.numeric(any(n < 2)),
         ext = max(gen) < 15 | any(n < 2)) %>%
  filter(!is.na(loglam)) %>%
  group_by(tau, ext, n.pop0, low.var, alpha) %>%
  summarise(ll = mean(loglam, na.rm = TRUE),
            kt = mean(k, na.rm = TRUE),
            vr = mean(varred, na.rm = TRUE),
            llvar = var(loglam, na.rm = TRUE),
            ktvar = var(k, na.rm = TRUE),
            vrvar = var(varred, na.rm = TRUE),
            n  = n()) %>%
  filter(tau > 0)

all.data %>%
  group_by(gen, n.pop0, low.var, alpha) %>%
  summarise(wbar = mean(wbar)) %>%
  ungroup() %>%
  filter(wbar > 1) %>%
  distinct(n.pop0, low.var, alpha, .keep_all = TRUE)

### Log lambda vs. k

all.tau %>%
  filter(!low.var) %>%
  ggplot(aes(x = kt, y = ll)) +
  geom_path(
    aes(
      group = interaction(alpha, ext),
      linetype = ext,
      colour = factor(alpha)
    )
    #arrow = arrow(length = unit(0.2, "npc"))
  ) +
  geom_point(
    aes(
      colour = factor(alpha),
      alpha = tau
    )
  ) +
  scale_color_manual(values = c('black', 'purple')) +
  facet_wrap(~ n.pop0)


ll.k = all.tau %>%
  rbind(., .) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  group_by(ext, n.pop0, low.var, alpha) %>%
  mutate(kt = c(NA, kt[1:(n()-1)])) %>%
  ungroup() %>%
  filter(!is.na(kt)) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  filter(!low.var) %>%
  ggplot(aes(x = kt, y = ll)) +
  geom_path(
    aes(
      group = interaction(alpha, ext),
      linetype = ext,
      colour = factor(alpha)
    )
    #arrow = arrow(length = unit(0.2, "npc"))
  ) +
  geom_point(
    aes(
      colour = factor(alpha),
      alpha = tau
    )
  ) +
  scale_color_manual(values = c('black', 'purple')) +
  facet_wrap(~ n.pop0)
  
ll.vr = all.tau %>%
  rbind(., .) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  group_by(ext, n.pop0, low.var, alpha) %>%
  mutate(vr = c(NA, vr[1:(n()-1)])) %>%
  ungroup() %>%
  filter(!is.na(vr)) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  filter(!low.var) %>%
  ggplot(aes(x = vr, y = ll)) +
  geom_path(
    aes(
      group = interaction(alpha, ext),
      linetype = ext,
      colour = factor(alpha)
    )
    #arrow = arrow(length = unit(0.2, "npc"))
  ) +
  geom_point(
    aes(
      colour = factor(alpha),
      alpha = tau
    )
  ) +
  scale_color_manual(values = c('black', 'purple')) +
  facet_wrap(~ n.pop0)

k.vr = all.tau %>%
  rbind(., .) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  group_by(ext, n.pop0, low.var, alpha) %>%
  mutate(kt = c(NA, kt[1:(n()-1)])) %>%
  ungroup() %>%
  filter(!is.na(kt)) %>%
  arrange(ext, n.pop0, low.var, alpha, tau) %>%
  filter(!low.var) %>%
  ggplot(aes(x = vr, y = kt)) +
  geom_path(
    aes(
      group = interaction(alpha, ext),
      linetype = ext,
      colour = factor(alpha)
    )
    #arrow = arrow(length = unit(0.2, "npc"))
  ) +
  geom_point(
    aes(
      colour = factor(alpha),
      alpha = tau
    )
  ) +
  scale_color_manual(values = c('black', 'purple')) +
  facet_wrap(~ n.pop0)

### Putting them together with cowplot

### Single variable plots

tau.loglam = all.tau %>%
  ungroup() %>%
  mutate(n.pop0  = factor(n.pop0 > 20, labels = c('small', 'large')),
         low.var = factor(low.var, labels = c('hi div.', 'lo div.'))) %>%
  ggplot(aes(x = tau, y = ll)) +
  geom_segment(
    aes(x = 1, xend = 15, y = 0, yend = 0),
    linetype = 3
  ) +
  geom_line(
    aes(
      colour = factor(alpha),
      linetype = ext
    )
  ) +
  geom_ribbon(
    aes(
      ymin = ll - 2 * sqrt(llvar / n),
      ymax = ll + 2 * sqrt(llvar / n),
      group = interaction(alpha, ext),
      fill = factor(alpha)
    ),
    alpha = 0.1
  ) +
  scale_x_reverse(labels = NULL) +
  scale_color_manual(values = c('black', 'purple')) +
  scale_fill_manual(values = c('black', 'purple')) +
  facet_wrap(~ paste(n.pop0, low.var, sep = ', '), ncol = 4) +
  labs(x = '', y = 'Log lambda') +
  theme(legend.position = 'none',
        plot.margin = margin(b = 0, r = 5, l = 5, unit = 'pt'),
        axis.ticks.x = element_blank())

tau.varred = all.tau %>%
  ungroup() %>%
  mutate(n.pop0  = factor(n.pop0 > 20, labels = c('small', 'large')),
         low.var = factor(low.var, labels = c('hi div.', 'lo div.'))) %>%
  ggplot(aes(x = tau, y = 1 - vr)) +
  geom_line(
    aes(
      colour = factor(alpha),
      linetype = ext
    )
  ) +
  geom_ribbon(
    aes(
      ymin = 1 - (vr - 2 * sqrt(vrvar / n)),
      ymax = 1 - (vr + 2 * sqrt(vrvar / n)),
      group = interaction(alpha, ext),
      fill = factor(alpha)
    ),
    alpha = 0.1
  ) +
  labs(x = '', y = 'Prop. of variance lost') +
  scale_x_reverse(labels = NULL) +
  scale_color_manual(values = c('black', 'purple')) +
  scale_fill_manual(values = c('black', 'purple')) +
  facet_wrap(~ paste(n.pop0, low.var, sep = ', '), ncol = 4) +
  theme(legend.position = 'none',
        axis.ticks.x = element_blank(),
        plot.margin = margin(t = 0, b = 0, r = 5, l = 5, unit = 'pt'))

tau.malada = all.tau %>%
  ungroup() %>%
  mutate(n.pop0  = factor(n.pop0 > 20, labels = c('small', 'large')),
         low.var = factor(low.var, labels = c('hi div.', 'lo div.'))) %>%
  ggplot(aes(x = tau, y = 1 - kt)) +
  geom_segment(
    aes(x = 1, xend = 15, y = 0, yend = 0),
    linetype = 3
  ) +
  geom_line(
    aes(
      colour = factor(alpha),
      linetype = ext
    )
  ) +
  geom_ribbon(
    aes(
      ymin = 1 - (kt - 2 * sqrt(ktvar / n)),
      ymax = 1 - (kt + 2 * sqrt(ktvar / n)),
      group = interaction(alpha, ext),
      fill = factor(alpha)
    ),
    alpha = 0.1
  ) +
  scale_x_reverse() +
  scale_color_manual(values = c('black', 'purple')) +
  scale_fill_manual(values = c('black', 'purple')) +
  facet_wrap(~ paste(n.pop0, low.var, sep = ', '), ncol = 4) +
  labs(x = 'Time to extinction (tau)', y = 'Maladaptation reduced') +
  theme(legend.position = 'none',
        plot.margin = margin(t = 0, r = 5, l = 5, unit = 'pt'))

cowplot::plot_grid(
  tau.loglam,
  tau.varred,
  tau.malada,
  nrow = 3
) %>%
  cowplot::save_plot(filename = 'simulations/analysis_results/figure_drafts/test_figs/onevar_tau.pdf',
                     base_width = 8, base_height = 6)

### Looking at rates by generation instead of tau

ext.vars = all.data %>%
  group_by(trial, n.pop0, low.var, alpha) %>%
  mutate(loglam = c(NA, diff(log(n))),
         d = abs(2.75 - gbar),
         k = c(NA, exp(diff(log(d)))),
         varred = c(NA, exp(diff(log(v))))) %>%
  mutate(tau = max(gen) - gen + 1 - as.numeric(any(n < 2)),
         ext = max(gen) < 15 | any(n < 2),
         ext.gen = max(gen) - as.numeric(any(n < 2))) %>%
  filter(!is.na(loglam) & !is.na(k) & !is.na(varred)) %>%
  group_by(ext.gen, gen, n.pop0, low.var, alpha) %>%
  summarise(ll = mean(loglam, na.rm = TRUE),
            kt = mean(k, na.rm = TRUE),
            vr = mean(varred, na.rm = TRUE),
            llvar = var(loglam, na.rm = TRUE),
            ktvar = var(k, na.rm = TRUE),
            vrvar = var(varred, na.rm = TRUE),
            n  = n())

ext.vars %>%
  ggplot(aes(x = gen, y = ll)) +
  geom_segment(
    aes(x = 1, xend = 15, y = 0, yend = 0),
    linetype = 3
  ) +
  geom_line(
    aes(
      colour = factor(alpha),
      group = ext.gen
    )
  ) +
  geom_ribbon(
    aes(
      ymin = ll - 2 * sqrt(llvar / n),
      ymax = ll + 2 * sqrt(llvar / n),
      group = interaction(alpha, ext.gen),
      fill = factor(alpha)
    ),
    alpha = 0.1
  ) +
  scale_color_manual(values = c('black', 'purple')) +
  scale_fill_manual(values = c('black', 'purple')) +
  facet_wrap(alpha ~ paste(n.pop0, low.var, sep = ', '), ncol = 4) +
  labs(x = '', y = 'Log lambda') +
  theme(legend.position = 'none',
        plot.margin = margin(b = 0, r = 5, l = 5, unit = 'pt'),
        axis.ticks.x = element_blank())

