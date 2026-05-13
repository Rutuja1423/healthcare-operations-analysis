"""
Healthcare Operations Intelligence Dashboard — Individual Page Generator
=========================================================================
Generates separate, high-quality dashboard page images for GitHub presentation.
Each page focuses on a specific analytical dimension.

Author: Rutuja Shinde
"""

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np
import os

# ============================================================
# Configuration
# ============================================================
sns.set_theme(style="whitegrid", font_scale=1.1)
plt.rcParams.update({
    'figure.dpi': 180,
    'savefig.dpi': 180,
    'font.family': 'sans-serif',
    'axes.titleweight': 'bold',
    'axes.titlesize': 14,
    'axes.labelsize': 12,
})

BG_COLOR = '#0F1923'
CARD_BG = '#162635'
TEXT_PRIMARY = '#FFFFFF'
TEXT_SECONDARY = '#8FA3B8'
GRID_COLOR = '#1E3448'
ACCENT_BLUE = '#00B4D8'
ACCENT_TEAL = '#48C9B0'
ACCENT_ORANGE = '#F39C12'
ACCENT_RED = '#E74C3C'
ACCENT_GREEN = '#27AE60'
ACCENT_PURPLE = '#A78BFA'

DEPT_COLORS = ['#00B4D8', '#48C9B0', '#F39C12', '#A78BFA', '#E74C3C', '#34D399']

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'screenshots')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# Data (derived from SQL query results)
# ============================================================
los_data = [
    2, 7, 2, 10, 1, 8, 2, 1, 7, 2, 5, 10,
    2, 2, 10, 2, 8, 7, 2, 2, 10, 1, 7, 2,
    3, 8, 2, 2, 8, 2, 2, 10, 1, 7, 2, 3,
    8, 2, 2, 8, 2, 2, 10, 7, 2, 3, 8, 2,
    5, 15, 12, 4, 6, 9, 3, 11, 1, 14, 3, 6
]

departments = ['Cardiology', 'Neurology', 'General Medicine', 'Orthopedics', 'Pediatrics', 'Emergency']
avg_los = [8.5, 7.2, 4.8, 6.1, 2.3, 1.8]

stay_categories = ['Short Stay\n(< 3 days)', 'Medium Stay\n(3-7 days)', 'Long Stay\n(> 7 days)']
stay_counts = [18, 14, 18]

risk_categories = ['Low Risk\n(Paid)', 'Medium Risk\n(Partial)', 'High Risk\n(Pending)', 'Critical\n(Denied)']
risk_amounts = [458200, 345000, 604000, 117000]
risk_counts = [35, 8, 7, 4]

months = ['Jan', 'Feb', 'Mar', 'Apr', 'May']
admissions = [10, 10, 10, 11, 9]
discharges = [9, 9, 10, 10, 8]

dept_revenue = [525000, 280000, 310000, 263000, 44500, 45000]

kpi_data = {
    'Total Patients': ('50', ACCENT_BLUE),
    'Avg LOS': ('5.8 days', ACCENT_TEAL),
    'Total Revenue': ('₹15.24L', ACCENT_GREEN),
    'Revenue/Patient': ('₹30,484', ACCENT_PURPLE),
    'Collection Rate': ('62.3%', ACCENT_ORANGE),
    '30-Day Readmission': ('38.0%', ACCENT_RED),
}


def _style_ax(ax, title=''):
    """Apply dark theme styling to an axis."""
    ax.set_facecolor(CARD_BG)
    ax.set_title(title, color=TEXT_PRIMARY, fontsize=14, fontweight='bold', pad=15)
    ax.tick_params(colors=TEXT_SECONDARY, labelsize=10)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['bottom'].set_color(GRID_COLOR)
    ax.spines['left'].set_color(GRID_COLOR)
    ax.xaxis.label.set_color(TEXT_SECONDARY)
    ax.yaxis.label.set_color(TEXT_SECONDARY)
    ax.set_axisbelow(True)
    ax.grid(True, color=GRID_COLOR, linewidth=0.5, alpha=0.6)


def _add_page_header(fig, title, subtitle=''):
    """Add a styled page header to a figure."""
    fig.text(0.5, 0.96, title,
             ha='center', va='top', fontsize=20, fontweight='bold',
             color=TEXT_PRIMARY, family='sans-serif')
    if subtitle:
        fig.text(0.5, 0.925, subtitle,
                 ha='center', va='top', fontsize=11,
                 color=TEXT_SECONDARY, style='italic')


# ============================================================
# Page 1: KPI Overview
# ============================================================
def generate_kpi_page():
    fig = plt.figure(figsize=(16, 9), facecolor=BG_COLOR)
    _add_page_header(fig,
                     'Healthcare Operations Intelligence Dashboard',
                     'Key Performance Indicators  ·  Jan – May 2024  ·  50 Patients  ·  80 Visits')

    # KPI Cards — top row
    card_width = 0.135
    card_height = 0.20
    start_x = 0.045
    card_y = 0.64
    gap = 0.012

    for i, (label, (value, color)) in enumerate(kpi_data.items()):
        x = start_x + i * (card_width + gap)
        # Card background with rounded rectangle
        rect = mpatches.FancyBboxPatch(
            (x, card_y), card_width, card_height,
            boxstyle="round,pad=0.012",
            facecolor=CARD_BG, edgecolor=color, linewidth=2,
            transform=fig.transFigure, figure=fig)
        fig.patches.append(rect)
        # Accent line at top
        line = mpatches.FancyBboxPatch(
            (x + 0.01, card_y + card_height - 0.015), card_width - 0.02, 0.008,
            boxstyle="round,pad=0.003",
            facecolor=color, edgecolor='none',
            transform=fig.transFigure, figure=fig)
        fig.patches.append(line)
        # Value
        fig.text(x + card_width / 2, card_y + card_height * 0.55, value,
                 ha='center', va='center', fontsize=22, fontweight='bold',
                 color=color, family='sans-serif')
        # Label
        fig.text(x + card_width / 2, card_y + card_height * 0.18, label,
                 ha='center', va='center', fontsize=9.5,
                 color=TEXT_SECONDARY, family='sans-serif')

    # Bottom section: two mini charts side by side
    ax_left = fig.add_axes([0.06, 0.08, 0.4, 0.45], facecolor=CARD_BG)
    _style_ax(ax_left, 'Monthly Admissions vs Discharges')
    x = np.arange(len(months))
    w = 0.3
    ax_left.bar(x - w/2, admissions, w, label='Admissions',
                color=ACCENT_BLUE, edgecolor='none', alpha=0.85)
    ax_left.bar(x + w/2, discharges, w, label='Discharges',
                color=ACCENT_TEAL, edgecolor='none', alpha=0.85)
    ax_left.plot(x, admissions, 'o-', color=ACCENT_ORANGE, linewidth=2, markersize=5, zorder=5)
    ax_left.set_xticks(x)
    ax_left.set_xticklabels(months, color=TEXT_SECONDARY)
    ax_left.set_ylabel('Count')
    ax_left.legend(fontsize=9, facecolor=CARD_BG, edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)
    ax_left.yaxis.set_major_locator(mticker.MaxNLocator(integer=True))

    ax_right = fig.add_axes([0.56, 0.08, 0.4, 0.45], facecolor=CARD_BG)
    _style_ax(ax_right, 'Patient Stay Category Distribution')
    colors_donut = [ACCENT_GREEN, ACCENT_ORANGE, ACCENT_RED]
    wedges, texts, autotexts = ax_right.pie(
        stay_counts, labels=stay_categories, autopct='%1.1f%%',
        colors=colors_donut, startangle=90, pctdistance=0.78,
        wedgeprops=dict(width=0.45, edgecolor=BG_COLOR, linewidth=3))
    for t in texts:
        t.set_color(TEXT_SECONDARY)
        t.set_fontsize(9)
    for at in autotexts:
        at.set_color(TEXT_PRIMARY)
        at.set_fontweight('bold')
        at.set_fontsize(11)
    ax_right.set_title('Patient Stay Category Distribution',
                       color=TEXT_PRIMARY, fontsize=14, fontweight='bold', pad=15)

    path = os.path.join(OUTPUT_DIR, 'kpi_overview.png')
    fig.savefig(path, bbox_inches='tight', facecolor=fig.get_facecolor(), pad_inches=0.3)
    plt.close(fig)
    print(f"  Saved: {path}")


# ============================================================
# Page 2: Department Performance
# ============================================================
def generate_department_page():
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7), facecolor=BG_COLOR)
    _add_page_header(fig,
                     'Department Performance Analysis',
                     'Average Length of Stay & Revenue Breakdown by Department')

    # Chart 1: Avg LOS by department
    _style_ax(ax1, 'Average Length of Stay by Department')
    bars = ax1.barh(departments, avg_los, color=DEPT_COLORS, edgecolor='none', height=0.55)
    ax1.axvline(np.mean(avg_los), color=ACCENT_ORANGE, linestyle='--', linewidth=1.5,
                label=f'Hospital Avg: {np.mean(avg_los):.1f}d')
    for bar, val in zip(bars, avg_los):
        ax1.text(val + 0.2, bar.get_y() + bar.get_height()/2,
                 f'{val:.1f} days', va='center', fontweight='bold',
                 fontsize=10, color=TEXT_PRIMARY)
    ax1.set_xlim(0, max(avg_los) + 3)
    ax1.invert_yaxis()
    ax1.set_xlabel('Days')
    ax1.legend(fontsize=9, facecolor=CARD_BG, edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)

    # Chart 2: Revenue by department
    _style_ax(ax2, 'Total Revenue by Department')
    rev_lakhs = [r / 100000 for r in dept_revenue]
    bars2 = ax2.bar(departments, rev_lakhs, color=DEPT_COLORS, edgecolor='none', width=0.55)
    for bar, val in zip(bars2, dept_revenue):
        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,
                 f'₹{val/1000:.0f}K', ha='center', fontweight='bold',
                 fontsize=9, color=TEXT_PRIMARY)
    ax2.set_ylabel('Revenue (₹ Lakhs)')
    ax2.set_xticklabels(departments, rotation=25, ha='right', color=TEXT_SECONDARY)
    ax2.set_ylim(0, max(rev_lakhs) + 1.5)

    fig.subplots_adjust(top=0.85, bottom=0.15, wspace=0.35, left=0.08, right=0.96)
    path = os.path.join(OUTPUT_DIR, 'department_performance.png')
    fig.savefig(path, bbox_inches='tight', facecolor=fig.get_facecolor(), pad_inches=0.3)
    plt.close(fig)
    print(f"  Saved: {path}")


# ============================================================
# Page 3: Billing & Revenue Risk
# ============================================================
def generate_billing_page():
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7), facecolor=BG_COLOR)
    _add_page_header(fig,
                     'Billing & Revenue Risk Analysis',
                     '₹7.21 Lakhs (47%) of Total Revenue At Risk from Pending & Denied Claims')

    # Chart 1: Revenue by Risk Category
    _style_ax(ax1, 'Revenue by Billing Risk Category')
    risk_colors = [ACCENT_GREEN, ACCENT_ORANGE, '#E67E22', ACCENT_RED]
    risk_lakhs = [a / 100000 for a in risk_amounts]
    bars = ax1.bar(range(len(risk_categories)), risk_lakhs,
                   color=risk_colors, edgecolor='none', width=0.55)
    ax1.set_xticks(range(len(risk_categories)))
    ax1.set_xticklabels(risk_categories, fontsize=9, color=TEXT_SECONDARY)
    ax1.set_ylabel('Amount (₹ Lakhs)')
    for bar, val, cnt in zip(bars, risk_amounts, risk_counts):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.15,
                 f'₹{val/100000:.1f}L\n({cnt} bills)',
                 ha='center', fontweight='bold', fontsize=9, color=TEXT_PRIMARY)
    ax1.set_ylim(0, max(risk_lakhs) + 2)

    # Chart 2: Collection funnel
    _style_ax(ax2, 'Revenue Collection Breakdown')
    total_rev = sum(risk_amounts)
    collected = risk_amounts[0]
    partial = risk_amounts[1]
    at_risk = risk_amounts[2] + risk_amounts[3]

    categories = ['Total Billed', 'Collected (Paid)', 'Partial Payment', 'At Risk\n(Pending+Denied)']
    values = [total_rev/100000, collected/100000, partial/100000, at_risk/100000]
    colors = [ACCENT_BLUE, ACCENT_GREEN, ACCENT_ORANGE, ACCENT_RED]

    bars2 = ax2.barh(categories, values, color=colors, edgecolor='none', height=0.5)
    for bar, val in zip(bars2, values):
        pct = val / (total_rev/100000) * 100
        ax2.text(val + 0.15, bar.get_y() + bar.get_height()/2,
                 f'₹{val:.1f}L ({pct:.0f}%)', va='center',
                 fontweight='bold', fontsize=10, color=TEXT_PRIMARY)
    ax2.set_xlim(0, max(values) + 5)
    ax2.set_xlabel('Amount (₹ Lakhs)')
    ax2.invert_yaxis()

    fig.subplots_adjust(top=0.85, bottom=0.12, wspace=0.4, left=0.1, right=0.96)
    path = os.path.join(OUTPUT_DIR, 'billing_risk_analysis.png')
    fig.savefig(path, bbox_inches='tight', facecolor=fig.get_facecolor(), pad_inches=0.3)
    plt.close(fig)
    print(f"  Saved: {path}")


# ============================================================
# Page 4: Patient Flow & Operational Insights
# ============================================================
def generate_patient_flow_page():
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12), facecolor=BG_COLOR)
    _add_page_header(fig,
                     'Patient Flow & Operational Insights',
                     'Admission Patterns, Length of Stay Distribution, and Throughput Analysis')

    # Chart 1: LOS Distribution
    _style_ax(ax1, 'Length of Stay Distribution')
    ax1.hist(los_data, bins=12, color=ACCENT_BLUE, edgecolor=BG_COLOR,
             alpha=0.85, linewidth=1.5)
    ax1.axvline(np.mean(los_data), color=ACCENT_ORANGE, linestyle='--',
                linewidth=2, label=f'Mean: {np.mean(los_data):.1f} days')
    ax1.axvline(np.median(los_data), color=ACCENT_TEAL, linestyle=':',
                linewidth=2, label=f'Median: {np.median(los_data):.0f} days')
    ax1.set_xlabel('Days')
    ax1.set_ylabel('Frequency')
    ax1.legend(fontsize=9, facecolor=CARD_BG, edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)

    # Chart 2: Monthly trend
    _style_ax(ax2, 'Monthly Admissions vs Discharges')
    x = np.arange(len(months))
    w = 0.28
    ax2.bar(x - w/2, admissions, w, label='Admissions',
            color=ACCENT_BLUE, edgecolor='none', alpha=0.85)
    ax2.bar(x + w/2, discharges, w, label='Discharges',
            color=ACCENT_TEAL, edgecolor='none', alpha=0.85)
    # Net flow line
    net = [a - d for a, d in zip(admissions, discharges)]
    ax2_twin = ax2.twinx()
    ax2_twin.plot(x, net, 's--', color=ACCENT_RED, linewidth=2,
                  markersize=6, label='Net Flow', zorder=5)
    ax2_twin.set_ylabel('Net Flow', color=ACCENT_RED)
    ax2_twin.tick_params(axis='y', colors=ACCENT_RED)
    ax2_twin.spines['right'].set_color(ACCENT_RED)
    ax2_twin.spines['top'].set_visible(False)
    ax2.set_xticks(x)
    ax2.set_xticklabels(months, color=TEXT_SECONDARY)
    ax2.set_ylabel('Count')
    ax2.legend(loc='upper left', fontsize=8, facecolor=CARD_BG,
               edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)
    ax2_twin.legend(loc='upper right', fontsize=8, facecolor=CARD_BG,
                    edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)
    ax2.yaxis.set_major_locator(mticker.MaxNLocator(integer=True))

    # Chart 3: LOS by department (horizontal grouped)
    _style_ax(ax3, 'LOS by Department vs Hospital Average')
    hospital_avg = np.mean(avg_los)
    colors_bars = [ACCENT_RED if v > hospital_avg else ACCENT_GREEN for v in avg_los]
    bars3 = ax3.barh(departments, avg_los, color=colors_bars, edgecolor='none', height=0.5)
    ax3.axvline(hospital_avg, color=ACCENT_ORANGE, linestyle='--', linewidth=1.5,
                label=f'Avg: {hospital_avg:.1f}d')
    for bar, val in zip(bars3, avg_los):
        ax3.text(val + 0.15, bar.get_y() + bar.get_height()/2,
                 f'{val:.1f}', va='center', fontweight='bold',
                 fontsize=10, color=TEXT_PRIMARY)
    ax3.set_xlim(0, max(avg_los) + 2.5)
    ax3.invert_yaxis()
    ax3.set_xlabel('Days')
    ax3.legend(fontsize=9, facecolor=CARD_BG, edgecolor=GRID_COLOR, labelcolor=TEXT_SECONDARY)

    # Chart 4: Stay Category donut
    _style_ax(ax4, '')
    ax4.set_title('Stay Category Breakdown', color=TEXT_PRIMARY,
                  fontsize=14, fontweight='bold', pad=15)
    ax4.axis('off')
    ax4.grid(False)
    colors_donut = [ACCENT_GREEN, ACCENT_ORANGE, ACCENT_RED]
    wedges, texts, autotexts = ax4.pie(
        stay_counts, labels=stay_categories, autopct='%1.1f%%',
        colors=colors_donut, startangle=90, pctdistance=0.78,
        wedgeprops=dict(width=0.45, edgecolor=BG_COLOR, linewidth=3))
    for t in texts:
        t.set_color(TEXT_SECONDARY)
        t.set_fontsize(9)
    for at in autotexts:
        at.set_color(TEXT_PRIMARY)
        at.set_fontweight('bold')
        at.set_fontsize(11)

    fig.subplots_adjust(top=0.90, bottom=0.06, hspace=0.38, wspace=0.35,
                        left=0.08, right=0.95)
    path = os.path.join(OUTPUT_DIR, 'patient_flow_insights.png')
    fig.savefig(path, bbox_inches='tight', facecolor=fig.get_facecolor(), pad_inches=0.3)
    plt.close(fig)
    print(f"  Saved: {path}")


# ============================================================
# Main
# ============================================================
if __name__ == '__main__':
    print("Generating dashboard pages...")
    generate_kpi_page()
    generate_department_page()
    generate_billing_page()
    generate_patient_flow_page()
    print(f"\nAll pages saved to: {OUTPUT_DIR}")
