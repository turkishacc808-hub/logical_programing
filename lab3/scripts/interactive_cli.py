#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
interactive_cli.py
Интерактивный клинический интерфейс экспертной системы кардиодиагностики.

Использование:
    python3 scripts/interactive_cli.py

Пользователь выбирает симптомы из пронумерованного списка,
получает диагноз, уверенность, объяснение и клинические рекомендации.
"""

import os
import sys
import re


# ──────────────────────────────────────────────────────────────
# База знаний
# ──────────────────────────────────────────────────────────────

SYMPTOMS = [
    'chest_pain',       'dyspnea',          'tachycardia',
    'bradycardia',      'peripheral_edema',  'fatigue',
    'palpitations',     'syncope',           'elevated_bp',
    'low_bp',           'cyanosis',          'diaphoresis',
    'st_elevation',     'irregular_rhythm',  'friction_rub',
]

SYMPTOM_LABELS = {
    'chest_pain':       'Боль в груди',
    'dyspnea':          'Одышка',
    'tachycardia':      'Тахикардия',
    'bradycardia':      'Брадикардия',
    'peripheral_edema': 'Периферические отёки',
    'fatigue':          'Быстрая утомляемость',
    'palpitations':     'Сердцебиение / перебои в работе сердца',
    'syncope':          'Обморок / кратковременная потеря сознания',
    'elevated_bp':      'Повышенное артериальное давление',
    'low_bp':           'Пониженное артериальное давление',
    'cyanosis':         'Цианоз (синюшность кожи/губ)',
    'diaphoresis':      'Холодный профузный пот',
    'st_elevation':     'Подъём сегмента ST на ЭКГ',
    'irregular_rhythm': 'Нерегулярный сердечный ритм',
    'friction_rub':     'Шум трения перикарда при аускультации',
}

DIAGNOSES = [
    'cad', 'heart_failure', 'arrhythmia',
    'hypertension', 'myocardial_infarction', 'pericarditis',
]

DIAGNOSIS_LABELS = {
    'cad':                   'Ишемическая болезнь сердца (ИБС)',
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
        'Направить на коронарографию; назначить антиагреганты (аспирин 75 мг/сут) и '
        'статины; мониторинг АД и ЭКГ в динамике. Плановая госпитализация.',
    'heart_failure':
        'Госпитализация в кардиологическое отделение. Диуретики (фуросемид), '
        'ингибиторы АПФ или сартаны. Контроль водного баланса и ЭхоКГ.',
    'arrhythmia':
        'Суточное мониторирование ЭКГ (Холтер). Антиаритмическая терапия по типу '
        'нарушения ритма. При синкопе — консультация для имплантации ЭКС.',
    'hypertension':
        'Гипотензивная терапия (блокаторы РААС, β-блокаторы). Диета с ограничением '
        'натрия (<2 г/сут). Самоконтроль АД дважды в сутки.',
    'myocardial_infarction':
        '⚠  ЭКСТРЕННАЯ ГОСПИТАЛИЗАЦИЯ! Вызвать СМП. Аспирин 300 мг немедленно. '
        'ЧКВ или тромболизис в течение 90 минут. Мониторинг тропонина I/T.',
    'pericarditis':
        'НПВС (ибупрофен 600 мг 3×/сут, 2 нед) + колхицин 0.5 мг 2×/сут. '
        'ЭхоКГ для исключения выпота/тампонады. Ограничение физических нагрузок 3 мес.',
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
    return [
        (rule_id, conf, required)
        for rule_id, diag, conf, required in RULES
        if diag == diagnosis and all(s in findings_set for s in required)
    ]


def compute_confidence(fired_rules):
    if not fired_rules:
        return 0.0
    product = 1.0
    for _, w, _ in fired_rules:
        product *= (1.0 - w)
    return 1.0 - product


def assess_all(findings):
    """Возвращает отсортированный список (diagnosis, confidence, fired_rules)."""
    findings_set = set(findings)

    raw = {}
    fired_map = {}
    for diag in DIAGNOSES:
        fired = get_fired_rules(findings_set, diag)
        raw[diag]       = compute_confidence(fired)
        fired_map[diag] = fired

    # НЕ-факторы
    result = []
    for diag in DIAGNOSES:
        excluded = False
        for d_a, d_b in EXCLUSIONS:
            if d_a == diag and raw.get(d_b, 0) > raw.get(d_a, 0):
                excluded = True
                break
        if not excluded and raw[diag] > 0:
            result.append((diag, raw[diag], fired_map[diag]))

    result.sort(key=lambda x: x[1], reverse=True)
    return result


# ──────────────────────────────────────────────────────────────
# Форматирование вывода
# ──────────────────────────────────────────────────────────────

DIVIDER  = '─' * 62
DIVIDER2 = '═' * 62
BLOCK_W  = 62


def header(text):
    print(f'\n{DIVIDER2}')
    pad = (BLOCK_W - len(text)) // 2
    print(' ' * pad + text)
    print(DIVIDER2)


def section(text):
    print(f'\n{DIVIDER}')
    print(f'  {text}')
    print(DIVIDER)


def confidence_bar(conf, width=30):
    filled = int(conf * width)
    bar    = '█' * filled + '░' * (width - filled)
    return f'[{bar}] {conf*100:5.1f}%'


def urgency_label(conf):
    if conf >= 0.90:
        return '⚠  ВЫСОКАЯ — требует немедленного вмешательства'
    elif conf >= 0.75:
        return '!  УМЕРЕННАЯ — плановое обследование'
    elif conf >= 0.55:
        return 'i  НИЗКАЯ — дополнительная диагностика'
    else:
        return '?  НЕДОСТАТОЧНО ДАННЫХ'


def print_result(findings, results):
    section('РЕЗУЛЬТАТЫ ДИАГНОСТИКИ')

    if not results:
        print('\n  Ни одно правило базы знаний не активировано.')
        print('  Рекомендация: расширить перечень клинических признаков.')
        return

    print(f'\n  Введено признаков: {len(findings)}')
    for s in findings:
        print(f'    • {SYMPTOM_LABELS.get(s, s)}')

    print(f'\n  Дифференциальный ряд ({len(results)} диагнозов):')
    print()
    for rank, (diag, conf, _) in enumerate(results, start=1):
        label   = DIAGNOSIS_LABELS.get(diag, diag)
        bar     = confidence_bar(conf)
        marker  = '►' if rank == 1 else ' '
        print(f'  {marker} {rank}. {label}')
        print(f'       {bar}')
    print()

    # Топ-диагноз
    top_diag, top_conf, top_fired = results[0]
    top_label = DIAGNOSIS_LABELS.get(top_diag, top_diag)

    section('ОСНОВНОЙ ДИАГНОЗ')
    print(f'\n  Диагноз:      {top_label}')
    print(f'  Уверенность:  {top_conf:.4f}  ({top_conf*100:.1f}%)')
    print(f'  Срочность:    {urgency_label(top_conf)}')

    # Объяснение (трасса активных правил)
    section('ОБЪЯСНЕНИЕ ВЫВОДА')
    if top_fired:
        print(f'\n  Активированные правила для «{top_label}»:')
        for rule_id, conf, required in top_fired:
            matched = [SYMPTOM_LABELS.get(s, s) for s in required]
            print(f'\n  → Правило {rule_id}  (вес {conf})')
            print(f'    Совпавшие признаки:')
            for m in matched:
                print(f'      ✔ {m}')
        formula = '  Формула: Conf = 1 − ∏(1 − wᵢ)'
        weights = ', '.join(str(c) for _, c, _ in top_fired)
        print(f'\n{formula}')
        print(f'  Веса активных правил: [{weights}]')
        print(f'  Итоговая уверенность: {top_conf:.4f}')
    else:
        print('  (Нет активных правил)')

    # Клинические рекомендации
    section('КЛИНИЧЕСКИЕ РЕКОМЕНДАЦИИ')
    action = ACTIONS.get(top_diag, 'Консультация кардиолога.')
    # Форматируем с переносами по словам
    words   = action.split()
    line    = '  '
    for w in words:
        if len(line) + len(w) + 1 > 60:
            print(line)
            line = '  ' + w + ' '
        else:
            line += w + ' '
    if line.strip():
        print(line)
    print()


# ──────────────────────────────────────────────────────────────
# Интерактивный цикл
# ──────────────────────────────────────────────────────────────

def print_symptom_menu():
    print('\n  Список доступных клинических признаков:')
    print()
    for i, sym in enumerate(SYMPTOMS, start=1):
        label = SYMPTOM_LABELS.get(sym, sym)
        print(f'  {i:2d}. {label}')
    print()
    print('  Введите номера признаков через запятую или пробел.')
    print('  Пример: 1, 3, 13   или   1 3 13')
    print()


def parse_selection(raw_input, max_index):
    """Разбирает строку с номерами, возвращает список индексов (0-based)."""
    tokens  = re.split(r'[,\s]+', raw_input.strip())
    indices = []
    errors  = []
    for tok in tokens:
        if not tok:
            continue
        if tok.isdigit():
            idx = int(tok)
            if 1 <= idx <= max_index:
                indices.append(idx - 1)
            else:
                errors.append(tok)
        else:
            errors.append(tok)
    if errors:
        print(f'\n  [!] Неизвестные значения (проигнорированы): {", ".join(errors)}')
    return list(set(indices))


def main():
    header('Экспертная система кардиологической диагностики')
    print('\n  Система реализует базу знаний из 22 клинических правил')
    print('  с НЕ-факторами для 6 кардиологических нозологий.')
    print('\n  Для выхода введите "выход", "exit" или "q".')

    session = 0
    while True:
        session += 1
        header(f'СЕССИЯ {session}')

        print_symptom_menu()

        try:
            raw = input('  Ваш выбор: ').strip()
        except (EOFError, KeyboardInterrupt):
            print('\n\n  До свидания!')
            break

        if raw.lower() in ('выход', 'exit', 'q', 'quit', ''):
            print('\n  До свидания!\n')
            break

        indices = parse_selection(raw, len(SYMPTOMS))

        if not indices:
            print('\n  [!] Не выбрано ни одного признака. Повторите ввод.')
            continue

        selected_symptoms = [SYMPTOMS[i] for i in indices]
        results = assess_all(selected_symptoms)
        print_result(selected_symptoms, results)

        # Спросить о продолжении
        try:
            cont = input('\n  Новая сессия? [Enter — да / q — выход]: ').strip().lower()
        except (EOFError, KeyboardInterrupt):
            print('\n\n  До свидания!')
            break

        if cont in ('q', 'quit', 'выход', 'exit'):
            print('\n  До свидания!\n')
            break


if __name__ == '__main__':
    main()
