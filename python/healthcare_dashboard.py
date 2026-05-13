"""
Healthcare Operations Analysis — Dashboard Visualizations
==========================================================
Generates publication-quality charts from SQL analysis results.
Uses hardcoded summary data derived from the SQL queries.

Author: Healthcare Data Analyst
"""

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import numpy as np
import os

# ============================================================
# Configuration
# ============================================================
sns.set_theme(style="whitegrid", font_scale=1.1)
plt.rcParams.update({
    'figure.dpi': 150,
    'savefig.dpi': 150,
    'font.family': 'sans-serif',
    'axes.titleweight': 'bold',
    'axes.titlesize': 13,
    'axes.labelsize': 11,
})

COLORS = {
    'primary':    '#1B4F72',
    'secondary':  '#2E86C1',
    'accent':     '#48C9B0',
    'warning':    '#F39C12',
    'danger':     '#E74C3C',
    'success':    '#27AE60',
    'light':      '#85C1E9',
    'dark':       '#1A5276',
}

DEPT_COLORS = ['#1B4F72', '#2E86C1', '#48C9B0', '#F39C12', '#E74C3C', '#8E44AD']

# ============================================================
# Data (derived from SQL query results)
# ============================================================

# LOS distribution for 50 patients (days)
los_data = [
    2, 7, 2, 10, 1, 8, 2, 1, 7, 2, 5, 10,
    2, 2, 10, 2, 8, 7, 2, 2, 10, 1, 7, 2,
    3, 8, 2, 2, 8, 2, 2, 10, 1, 7, 2, 3,
    8, 2, 2, 8, 2, 2, 10, 7, 2, 3, 8, 2,
    5, 15, 12, 4, 6, 9, 3, 11, 1, 14, 3, 6
]

# Average LOS by department
departments = ['Cardiology', 'Neurology', 'General Medicine', 'Orthopedics', 'Pediatrics', 'Emergency']
avg_los = [8.5, 7.2, 4.8, 6.1, 2.3, 1.8]

# Stay category distribution
stay_categories = ['Short Stay\n(< 3 days)', 'Medium Stay\n(3-7 days)', 'Long Stay\n(> 7 days)']
stay_counts = [18, 14, 18]

# Billing risk distribution
risk_categories = ['Low Risk\n(Paid)', 'Medium Risk\n(Partial)', 'High Risk\n(Pending)', 'Critical\n(Denied)']
risk_amounts = [458200, 345000, 604000, 117000]
risk_counts = [35, 8, 7, 4]

# Monthly admissions trend
months = ['Jan', 'Feb', 'Mar', 'Apr', 'May']
admissions = [10, 10, 10, 11, 9]
discharges = [9, 9, 10, 10, 8]

# Department revenue
dept_revenue = [525000, 280000, 310000, 263000, 44500, 45000]

# KPI Summary
kpi_labels = [
    'Total Patients', 'Avg LOS (days)', 'Total Revenue',
    'Revenue/Patient', 'Collection Rate', '30-Day Readmission'
]
kpi_values = ['50', '5.8', '₹15,24,200', '₹30,484', '62.3%', '38.0%']


# ============================================================
# Generate Dashboard
# ============================================================
def create_dashboard():
    fig = plt.figure(figsize=(20, 24), facecolor='#F8F9FA')
    fig.suptitle(
        'Healthcare Operations Analysis Dashboard',
        fontsize=22, fontweight='bold', color=COLORS['dark'],
        y=0.98
    )
    fig.text(
        0.5, 0.965,
        'Hospital Performance Metrics  |  Jan – May 2024  |  50 Patients  |  80 Visits',
        ha='center', fontsize=12, color='#666666', style='italic'
    )

    gs = fig.add_gridspec(4, 2, hspace=0.35, wspace=0.3,
                          top=0.94, bottom=0.03, left=0.08, right=0.95)

    # ----------------------------------------------------------
    # Chart 1: LOS Distribution (Histogram + KDE)
    # ----------------------------------------------------------
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.hist(los_data, bins=15, color=COLORS['secondary'], edgecolor='white',
             alpha=0.8, label='Frequency')
    ax1_kde = ax1.twinx()
    sns.kdeplot(los_data, ax=ax1_kde, color=COLORS['danger'], linewidth=2.5,
                label='KDE')
    ax1.set_title('Length of Stay Distribution', pad=15)
    ax1.set_xlabel('Days')
    ax1.set_ylabel('Frequency')
    ax1_kde.set_ylabel('Density')
    ax1_kde.set_yticks([])
    ax1.axvline(np.mean(los_data), color=COLORS['warning'], linestyle='--',
                linewidth=2, label=f'Mean: {np.mean(los_data):.1f} days')
    ax1.legend(loc='upper right', fontsize=9)

    # ----------------------------------------------------------
    # Chart 2: Average LOS by Department
    # ----------------------------------------------------------
    ax2 = fig.add_subplot(gs[0, 1])
    bars = ax2.barh(departments, avg_los, color=DEPT_COLORS, edgecolor='white',
                    height=0.6)
    ax2.set_title('Average Length of Stay by Department', pad=15)
    ax2.set_xlabel('Days')
    for bar, val in zip(bars, avg_los):
        ax2.text(val + 0.15, bar.get_y() + bar.get_height()/2,
                 f'{val:.1f}', va='center', fontweight='bold', fontsize=10)
    ax2.set_xlim(0, max(avg_los) + 2)
    ax2.invert_yaxis()

    # ----------------------------------------------------------
    # Chart 3: Stay Category Breakdown (Donut)
    # ----------------------------------------------------------
    ax3 = fig.add_subplot(gs[1, 0])
    colors_donut = [COLORS['success'], COLORS['warning'], COLORS['danger']]
    wedges, texts, autotexts = ax3.pie(
        stay_counts, labels=stay_categories, autopct='%1.1f%%',
        colors=colors_donut, startangle=90, pctdistance=0.78,
        wedgeprops=dict(width=0.45, edgecolor='white', linewidth=2)
    )
    for autotext in autotexts:
        autotext.set_fontweight('bold')
        autotext.set_fontsize(11)
    ax3.set_title('Patient Stay Category Distribution', pad=15)

    # ----------------------------------------------------------
    # Chart 4: Billing Risk — Revenue at Risk
    # ----------------------------------------------------------
    ax4 = fig.add_subplot(gs[1, 1])
    risk_colors = [COLORS['success'], COLORS['warning'], '#E67E22', COLORS['danger']]
    bars4 = ax4.bar(risk_categories, [a/100000 for a in risk_amounts],
                    color=risk_colors, edgecolor='white', width=0.6)
    ax4.set_title('Revenue by Billing Risk Category', pad=15)
    ax4.set_ylabel('Amount (₹ Lakhs)')
    for bar, val, cnt in zip(bars4, risk_amounts, risk_counts):
        ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.15,
                 f'₹{val/100000:.1f}L\n({cnt} bills)',
                 ha='center', fontweight='bold', fontsize=9)
    ax4.set_ylim(0, max(risk_amounts)/100000 + 1.5)

    # ----------------------------------------------------------
    # Chart 5: Monthly Admissions & Discharges Trend
    # ----------------------------------------------------------
    ax5 = fig.add_subplot(gs[2, 0])
    x = np.arange(len(months))
    w = 0.3
    bars_adm = ax5.bar(x - w/2, admissions, w, label='Admissions',
                       color=COLORS['secondary'], edgecolor='white')
    bars_dis = ax5.bar(x + w/2, discharges, w, label='Discharges',
                       color=COLORS['accent'], edgecolor='white')
    ax5.plot(x, admissions, 'o-', color=COLORS['dark'], linewidth=2,
             markersize=6, zorder=5)
    ax5.set_title('Monthly Admissions vs Discharges', pad=15)
    ax5.set_xlabel('Month (2024)')
    ax5.set_ylabel('Count')
    ax5.set_xticks(x)
    ax5.set_xticklabels(months)
    ax5.legend(fontsize=10)
    ax5.yaxis.set_major_locator(mticker.MaxNLocator(integer=True))

    # ----------------------------------------------------------
    # Chart 6: Department Revenue Comparison
    # ----------------------------------------------------------
    ax6 = fig.add_subplot(gs[2, 1])
    bars6 = ax6.bar(departments, [r/1000 for r in dept_revenue],
                    color=DEPT_COLORS, edgecolor='white', width=0.6)
    ax6.set_title('Total Revenue by Department', pad=15)
    ax6.set_ylabel('Revenue (₹ Thousands)')
    ax6.set_xticklabels(departments, rotation=30, ha='right')
    for bar, val in zip(bars6, dept_revenue):
        ax6.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5,
                 f'₹{val/1000:.0f}K', ha='center', fontweight='bold', fontsize=9)
    ax6.set_ylim(0, max(dept_revenue)/1000 + 60)

    # ----------------------------------------------------------
    # KPI Summary Cards (bottom row)
    # ----------------------------------------------------------
    ax_kpi = fig.add_subplot(gs[3, :])
    ax_kpi.set_xlim(0, 6)
    ax_kpi.set_ylim(0, 1)
    ax_kpi.axis('off')
    ax_kpi.set_title('Key Performance Indicators', pad=20, fontsize=16)

    kpi_colors = [COLORS['primary'], COLORS['secondary'], COLORS['success'],
                  COLORS['accent'], COLORS['warning'], COLORS['danger']]

    for i, (label, value) in enumerate(zip(kpi_labels, kpi_values)):
        x_pos = i + 0.5
        # Card background
        rect = plt.Rectangle((i + 0.05, 0.1), 0.9, 0.75,
                              facecolor=kpi_colors[i], alpha=0.12,
                              edgecolor=kpi_colors[i], linewidth=2,
                              transform=ax_kpi.transData, zorder=1)
        ax_kpi.add_patch(rect)
        # Value
        ax_kpi.text(x_pos, 0.58, value, ha='center', va='center',
                    fontsize=18, fontweight='bold', color=kpi_colors[i])
        # Label
        ax_kpi.text(x_pos, 0.30, label, ha='center', va='center',
                    fontsize=10, color='#444444')

    # Save
    output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'dashboards')
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'healthcare_dashboard.png')
    fig.savefig(output_path, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"Dashboard saved to: {output_path}")
    return output_path


if __name__ == '__main__':
    create_dashboard()
