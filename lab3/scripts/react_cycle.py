#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
react_cycle.py
Симуляция ReAct-агента (Reason + Act) для кардиологической диагностики.
12 итераций: Perceive → Reason → Act.
Сохраняет лог в artifacts/react_log.txt.
Генерирует report/figures/react_timeline.png.
"""

import os
import sys
import random
import math
import time

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# ──────────────────────────────────────────────────────────────
# Пути
# ──────────────────────────────────────────────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
BASE_DIR     = os.path.dirname(SCRIPT_DIR)
ARTIFACT_DIR = os.path.join(BASE_DIR, 'artifacts')
FIG_DIR      = os.path.join(BASE_DIR, 'report', 'figures')

os.makedirs(ARTIFACT_DIR, exist_ok=True)
os.makedirs(FIG_DIR,      exist_ok=True)

random.seed(2026)

# ──────────────────────────────────────────────────────────────
# База знаний (дублирована для автономности скрипта)
# ──────────────────────────────────────────────────────────────

SYMPTOMS = [
    'chest_pain', 'dyspnea', 'tachycardia', 'bradycardia',
    'peripheral_edema', 'fatigue', 'palpitations', 'syncope',
    'elevated_bp', 'low_bp', 'cyanosis', 'diaphoresis',
    'st_elevation', 'irregular_rhythm', 'friction_rub',
]

SYMPTOM_LABELS = {
    'chest_pain':       'боль в груди',
    'dyspnea':          'одышка',
    'tachycardia':      'тахикардия',
    'bradycardia':      'брадикардия',
    'peripheral_edema': 'периферические отёки',
    'fatigue':          'быстрая утомляемость',
    'palpitations':     'сердцебиение',
    'syncope':          'обморок',
    'elevated_bp':      'повышенное АД',
    'low_bp':           'пониженное АД',
    'cyanosis':         'цианоз',
    'diaphoresis':      'холодный пот',
    'st_elevation':     'подъём ST',
    'irregular_rhythm': 'нерегулярный ритм',
    'friction_rub':     'шум трения',
}

DIAGNOSES = [
    'cad', 'heart_failure', 'arrhythmia',
    'hypertension', 'myocardial_infarction', 'pericarditis',
]

DIAGNOSIS_LABELS = {
    'cad':                   'Ишемическая болезнь сердца',
    'heart_failure':         'Сердечная недостаточность',
    'arrhythmia':            'Аритмия',
    'hypertension':          'Гипертоническая болезнь',
    'myocardial_infarction': 'Инфаркт миокарда',
    'pericarditis':          'Перикардит',
}

RULES = [
    ('cad_r1', 'cad', 0.85, ['chest_pain', 'dyspnea', 'fatigue']),
    ('cad_r2', 'cad', 0.80, ['chest_pain', 'elevated_bp', 'tachycardia']),
    ('cad_r3', 'cad', 0.70, ['chest_pain', 'diaphoresis', 'dyspnea']),
    ('cad_r4', 'cad', 0.65, ['fatigue', 'dyspnea', 'elevated_bp']),
    ('hf_r1',  'heart_failure', 0.88, ['dyspnea', 'peripheral_edema', 'fatigue']),
    ('hf_r2',  'heart_failure', 0.82, ['dyspnea', 'cyanosis', 'peripheral_edema']),
    ('hf_r3',  'heart_failure', 0.75, ['tachycardia', 'peripheral_edema', 'fatigue']),
    ('hf_r4',  'heart_failure', 0.68, ['dyspnea', 'low_bp', 'fatigue']),
    ('arr_r1', 'arrhythmia', 0.90, ['palpitations', 'irregular_rhythm', 'syncope']),
    ('arr_r2', 'arrhythmia', 0.85, ['tachycardia', 'palpitations', 'irregular_rhythm']),
    ('arr_r3', 'arrhythmia', 0.78, ['bradycardia', 'syncope', 'fatigue']),
    ('arr_r4', 'arrhythmia', 0.65, ['palpitations', 'dyspnea', 'irregular_rhythm']),
    ('htn_r1', 'hypertension', 0.87, ['elevated_bp', 'chest_pain', 'fatigue']),
    ('htn_r2', 'hypertension', 0.80, ['elevated_bp', 'tachycardia', 'palpitations']),
    ('htn_r3', 'hypertension', 0.75, ['elevated_bp', 'dyspnea', 'fatigue']),
    ('htn_r4', 'hypertension', 0.60, ['elevated_bp', 'peripheral_edema', 'fatigue']),
    ('mi_r1',  'myocardial_infarction', 0.95, ['chest_pain', 'st_elevation', 'diaphoresis']),
    ('mi_r2',  'myocardial_infarction', 0.92, ['chest_pain', 'st_elevation', 'low_bp']),
    ('mi_r3',  'myocardial_infarction', 0.88, ['chest_pain', 'diaphoresis', 'low_bp', 'cyanosis']),
    ('mi_r4',  'myocardial_infarction', 0.78, ['chest_pain', 'dyspnea', 'st_elevation', 'tachycardia']),
    ('peri_r1','pericarditis', 0.93, ['chest_pain', 'friction_rub', 'dyspnea']),
    ('peri_r2','pericarditis', 0.87, ['friction_rub', 'tachycardia', 'fatigue']),
    ('peri_r3','pericarditis', 0.80, ['chest_pain', 'friction_rub', 'elevated_bp']),
    ('peri_r4','pericarditis', 0.72, ['friction_rub', 'diaphoresis', 'fatigue']),
]

ACTIONS = {
    'cad':
        'Направить на коронарографию; антиагреганты и статины; мониторинг АД.',
    'heart_failure':
        'Госпитализация; диуретики, иАПФ; контроль водного баланса.',
    'arrhythmia':
        'Холтер-мониторирование; антиаритмическая терапия; при синкопе — ЭКС.',
    'hypertension':
        'Гипотензивная терапия; диета; контроль АД 2×/сутки.',
    'myocardial_infarction':
        'ЭКСТРЕННАЯ ГОСПИТАЛИЗАЦИЯ! ЧКВ в течение 90 мин; аспирин 300 мг немедленно.',
    'pericarditis':
        'НПВС + колхицин; ЭхоКГ для исключения тампонады; ограничение нагрузок.',
}

EXCLUSIONS = [
    ('myocardial_infarction', 'cad'),
    ('cad', 'myocardial_infarction'),
    ('pericarditis', 'heart_failure'),
    ('heart_failure', 'pericarditis'),
]


# ──────────────────────────────────────────────────────────────
# Механизм вывода
# ──────────────────────────────────────────────────────────────

def get_fired_rules(findings_set, diagnosis):
    fired = []
    for rule_id, diag, conf, required in RULES:
        if diag == diagnosis and all(s in findings_set for s in required):
            fired.append((rule_id, conf))
    return fired


def compute_confidence(fired_rules):
    if not fired_rules:
        return 0.0
    product = 1.0
    for _, w in fired_rules:
        product *= (1.0 - w)
    return 1.0 - product


def assess(findings):
    """Возвращает dict {diag: confidence}."""
    findings_set = set(findings)
    raw = {}
    for diag in DIAGNOSES:
        fired = get_fired_rules(findings_set, diag)
        raw[diag] = compute_confidence(fired)

    # НЕ-факторы
    result = {}
    for diag in DIAGNOSES:
        excluded = False
        for d_a, d_b in EXCLUSIONS:
            if d_a == diag and raw.get(d_b, 0) > raw.get(d_a, 0):
                excluded = True
                break
        result[diag] = 0.0 if excluded else raw[diag]
    return result


# ──────────────────────────────────────────────────────────────
# ReAct-агент
# ──────────────────────────────────────────────────────────────

class CardioReActAgent:
    """
    ReAct-агент для кардиологической диагностики.

    Сценарий: пациент с инфарктом миокарда.
    Агент начинает с неполных данных и постепенно собирает
    дополнительные клинические признаки, уточняя диагноз.
    """

    # Полный набор симптомов пациента (известен агенту постепенно)
    PATIENT_TRUE_SYMPTOMS = [
        'chest_pain', 'st_elevation', 'diaphoresis',
        'low_bp', 'cyanosis', 'tachycardia', 'dyspnea',
    ]
    TRUE_DIAGNOSIS = 'myocardial_infarction'

    # Порядок добавления симптомов по итерациям
    SYMPTOM_REVEAL_SCHEDULE = {
        1:  ['chest_pain'],
        2:  ['chest_pain', 'tachycardia'],
        3:  ['chest_pain', 'tachycardia', 'diaphoresis'],
        4:  ['chest_pain', 'tachycardia', 'diaphoresis', 'dyspnea'],
        5:  ['chest_pain', 'tachycardia', 'diaphoresis', 'dyspnea', 'fatigue'],
        6:  ['chest_pain', 'tachycardia', 'diaphoresis', 'dyspnea', 'low_bp'],
        7:  ['chest_pain', 'tachycardia', 'diaphoresis', 'dyspnea', 'low_bp', 'st_elevation'],
        8:  ['chest_pain', 'st_elevation', 'diaphoresis', 'low_bp', 'tachycardia'],
        9:  ['chest_pain', 'st_elevation', 'diaphoresis', 'low_bp', 'tachycardia', 'dyspnea'],
        10: ['chest_pain', 'st_elevation', 'diaphoresis', 'low_bp', 'tachycardia', 'dyspnea', 'cyanosis'],
        11: ['chest_pain', 'st_elevation', 'diaphoresis', 'low_bp', 'cyanosis', 'tachycardia', 'dyspnea'],
        12: ['chest_pain', 'st_elevation', 'diaphoresis', 'low_bp', 'cyanosis', 'tachycardia', 'dyspnea'],
    }

    def __init__(self):
        self.iteration    = 0
        self.log_lines    = []
        self.confidences  = []   # уверенность в топ-диагнозе
        self.top_diags    = []   # название топ-диагноза

    def _log(self, msg, also_print=True):
        self.log_lines.append(msg)
        if also_print:
            print(msg)

    def perceive(self, iteration):
        """Фаза наблюдения: получаем текущий набор симптомов."""
        findings = self.SYMPTOM_REVEAL_SCHEDULE.get(iteration, self.PATIENT_TRUE_SYMPTOMS)
        # Добавляем небольшой шум (случайные ложноположительные)
        noise_candidates = ['fatigue', 'palpitations', 'elevated_bp']
        noisy_findings = list(findings)
        if iteration <= 5:
            for nc in noise_candidates:
                if random.random() < 0.25 and nc not in noisy_findings:
                    noisy_findings.append(nc)
        return noisy_findings

    def reason(self, findings):
        """Фаза рассуждения: применяем базу знаний."""
        scores = assess(findings)
        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        return ranked

    def act(self, ranked, iteration):
        """Фаза действия: выбираем клиническое действие."""
        if not ranked or ranked[0][1] == 0.0:
            return 'НАБЛЮДЕНИЕ', 'Недостаточно данных для диагноза.'

        top_diag, top_conf = ranked[0]

        if top_conf >= 0.90:
            urgency = 'ЭКСТРЕННОЕ ДЕЙСТВИЕ'
        elif top_conf >= 0.75:
            urgency = 'ПЛАНОВОЕ ДЕЙСТВИЕ'
        else:
            urgency = 'ДОПОЛНИТЕЛЬНОЕ ОБСЛЕДОВАНИЕ'

        action_text = ACTIONS.get(top_diag, 'Консультация кардиолога.')
        return urgency, action_text

    def run(self):
        """Запуск 12 итераций ReAct-цикла."""
        self._log('=' * 65)
        self._log('ReAct-агент кардиологической диагностики')
        self._log('Сценарий: пациент М., 58 лет. Экстренное обращение.')
        self._log('Истинный диагноз: Инфаркт миокарда')
        self._log('=' * 65)

        for it in range(1, 13):
            self.iteration = it
            self._log(f'\n─── Итерация {it:2d} ─────────────────────────────────────')

            # PERCEIVE
            findings = self.perceive(it)
            findings_ru = ', '.join(SYMPTOM_LABELS.get(s, s) for s in findings)
            self._log(f'[PERCEIVE] Наблюдаемые признаки ({len(findings)}): {findings_ru}')

            # REASON
            ranked = self.reason(findings)
            top_diag, top_conf = ranked[0] if ranked else ('unknown', 0.0)
            top_label = DIAGNOSIS_LABELS.get(top_diag, top_diag)

            self._log(f'[REASON]   Топ-1: {top_label} ({top_conf:.4f})')
            if len(ranked) >= 2:
                d2, c2 = ranked[1]
                self._log(f'           Топ-2: {DIAGNOSIS_LABELS.get(d2, d2)} ({c2:.4f})')

            # Записываем для графика
            self.confidences.append(top_conf)
            self.top_diags.append(top_diag)

            # ACT
            urgency, action = self.act(ranked, it)
            self._log(f'[ACT]      {urgency}: {action}')

            # Проверка: верен ли диагноз?
            if top_diag == self.TRUE_DIAGNOSIS:
                self._log(f'           ✔ Диагноз совпадает с истинным')
            else:
                self._log(f'           ✗ Диагноз не совпадает (истинный: {self.TRUE_DIAGNOSIS})')

        self._log('\n' + '=' * 65)
        self._log('Итог ReAct-цикла:')
        final_diag = self.top_diags[-1]
        final_conf = self.confidences[-1]
        self._log(f'  Финальный диагноз: {DIAGNOSIS_LABELS.get(final_diag, final_diag)}')
        self._log(f'  Уверенность: {final_conf:.4f}')
        if final_diag == self.TRUE_DIAGNOSIS:
            self._log('  Статус: ВЕРНО')
        else:
            self._log(f'  Статус: ОШИБКА (ожидался {self.TRUE_DIAGNOSIS})')
        self._log('=' * 65)

        return self.confidences, self.top_diags


def save_log(log_lines, path):
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(log_lines))
    print(f'\n  [OK] Лог сохранён: {path}')


def plot_react_timeline(confidences, top_diags, output_path):
    """Линейный график уверенности по 12 итерациям."""
    iterations = list(range(1, len(confidences) + 1))
    true_diag  = CardioReActAgent.TRUE_DIAGNOSIS

    fig, ax = plt.subplots(figsize=(10, 5))

    # Основная кривая
    ax.plot(iterations, confidences, 'o-', color='#2471A3',
            linewidth=2.2, markersize=8, zorder=3, label='Уверенность (Инфаркт миокарда)')

    # Раскраска точек: зелёные = верный диагноз, красные = нет
    for i, (it, conf, diag) in enumerate(zip(iterations, confidences, top_diags)):
        color = '#27AE60' if diag == true_diag else '#E74C3C'
        ax.plot(it, conf, 'o', color=color, markersize=9, zorder=4)

    # Порог действия
    ax.axhline(0.90, color='#C0392B', linestyle='--',
               linewidth=1.8, label='Порог экстренного действия (0.90)')

    # Зона уверенности
    ax.fill_between(iterations, confidences, alpha=0.12, color='#2471A3')

    # Аннотации поворотных точек
    ax.annotate('Добавлен\nподъём ST',
                xy=(7, confidences[6]),
                xytext=(7.3, confidences[6] - 0.15),
                arrowprops=dict(arrowstyle='->', color='#555'),
                fontsize=8.5, color='#333')

    ax.annotate('Верный диагноз\nпервый раз',
                xy=(7, confidences[6]),
                xytext=(5.5, confidences[6] + 0.05),
                arrowprops=dict(arrowstyle='->', color='#27AE60'),
                fontsize=8.5, color='#27AE60')

    # Легенда
    correct_patch  = mpatches.Patch(color='#27AE60', label='Верный диагноз')
    wrong_patch    = mpatches.Patch(color='#E74C3C', label='Неверный диагноз')
    ax.legend(handles=[
        plt.Line2D([0], [0], color='#2471A3', lw=2, label='Уверенность'),
        plt.Line2D([0], [0], color='#C0392B', lw=2, linestyle='--',
                   label='Порог действия (0.90)'),
        correct_patch,
        wrong_patch,
    ], fontsize=9, loc='lower right')

    ax.set_xlabel('Номер итерации ReAct', fontsize=11)
    ax.set_ylabel('Уверенность в диагнозе', fontsize=11)
    ax.set_title('Динамика диагностической уверенности в ReAct-цикле\n'
                 'Сценарий: Инфаркт миокарда (пациент М., 58 лет)',
                 fontsize=11, fontweight='bold')
    ax.set_xlim(0.5, 12.5)
    ax.set_ylim(0, 1.05)
    ax.set_xticks(iterations)
    ax.grid(alpha=0.35, linestyle='--')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f'  [OK] {output_path}')


def main():
    print('\nЗапуск ReAct-агента кардиологической диагностики')
    print('─' * 60)

    agent = CardioReActAgent()
    confidences, top_diags = agent.run()

    # Сохранить лог
    log_path = os.path.join(ARTIFACT_DIR, 'react_log.txt')
    save_log(agent.log_lines, log_path)

    # Сгенерировать график
    timeline_path = os.path.join(FIG_DIR, 'react_timeline.png')
    plot_react_timeline(confidences, top_diags, timeline_path)

    print('\nReAct-цикл завершён.')


if __name__ == '__main__':
    main()
