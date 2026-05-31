#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
专利交底书自动生成脚本
根据用户提供的技术信息，生成格式规范的Word文档
"""

from docx import Document
from docx.shared import Pt, RGBColor, Inches, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import json
from datetime import datetime

def add_heading_with_line(doc, text, level=1):
    """添加带下划线的标题"""
    heading = doc.add_heading(text, level=level)
    heading.alignment = WD_ALIGN_PARAGRAPH.LEFT

    # 设置标题样式
    for run in heading.runs:
        run.font.size = Pt(14 if level == 1 else 12)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0, 51, 102)

    return heading

def set_cell_background(cell, fill):
    """设置表格单元格背景色"""
    shading_elm = OxmlElement('w:shd')
    shading_elm.set(qn('w:fill'), fill)
    cell._element.get_or_add_tcPr().append(shading_elm)

def generate_disclosure_document(disclosure_data, output_path):
    """
    根据交底信息生成Word文档

    Args:
        disclosure_data (dict): 包含交底书信息的字典
        output_path (str): 输出文件路径
    """

    doc = Document()

    # 设置页边距
    sections = doc.sections
    for section in sections:
        section.top_margin = Cm(2.54)
        section.bottom_margin = Cm(2.54)
        section.left_margin = Cm(2.54)
        section.right_margin = Cm(2.54)

    # ===== 标题页 =====
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title_run = title.add_run(disclosure_data.get('title', '减振器技术发明'))
    title_run.font.size = Pt(24)
    title_run.font.bold = True
    title_run.font.color.rgb = RGBColor(0, 51, 102)

    doc.add_paragraph()

    # 基本信息表
    info_table = doc.add_table(rows=5, cols=2)
    info_table.style = 'Light Grid Accent 1'

    info_items = [
        ('发明名称', disclosure_data.get('title', '')),
        ('发明人', disclosure_data.get('inventor', '待填写')),
        ('申报日期', datetime.now().strftime('%Y年%m月%d日')),
        ('技术领域', disclosure_data.get('tech_field', '')),
        ('文件编号', disclosure_data.get('file_number', '待分配'))
    ]

    for idx, (label, value) in enumerate(info_items):
        cells = info_table.rows[idx].cells
        cells[0].text = label
        cells[1].text = value
        set_cell_background(cells[0], 'D3D3D3')

    doc.add_paragraph()
    doc.add_page_break()

    # ===== 第一章：技术背景与现状 =====
    add_heading_with_line(doc, '第一章  技术背景与现状')

    background = disclosure_data.get('background', {})

    doc.add_heading('1.1  减振器技术的重要性', level=2)
    doc.add_paragraph(background.get('importance',
        '减振器是车辆悬架系统的关键部件，直接影响车辆的驾驶舒适性、安全性和NVH（噪音、振动、硬度）性能。'
        '随着汽车工业的发展，对减振器的性能要求不断提高。'))

    doc.add_heading('1.2  市场对减振器的技术需求', level=2)
    doc.add_paragraph(background.get('market_demand',
        '当前市场对减振器的主要需求包括：\n'
        '• 更好的舒适性和操控性平衡\n'
        '• 更低的NVH性能\n'
        '• 更长的使用寿命和可靠性\n'
        '• 对电动车的适配能力'))

    doc.add_heading('1.3  现有技术的主要瓶颈', level=2)
    doc.add_paragraph(background.get('existing_limitation',
        disclosure_data.get('problem_description', '现有减振器技术存在以下主要局限和瓶颈。')))

    doc.add_page_break()

    # ===== 第二章：现有技术分析 =====
    add_heading_with_line(doc, '第二章  现有技术分析')

    doc.add_heading('2.1  主流减振器技术方案', level=2)
    existing = disclosure_data.get('existing_analysis', {})
    doc.add_paragraph(existing.get('mainstream_solutions',
        '目前市场上主流的减振器技术包括被动减振器（双筒式、单筒式）和主动/半主动减振器（CDC电控、MRC电磁）等。'))

    doc.add_heading('2.2  现有方案的优势与局限', level=2)

    # 对比表
    comparison_table = doc.add_table(rows=1, cols=4)
    comparison_table.style = 'Light Grid Accent 1'
    hdr_cells = comparison_table.rows[0].cells
    headers = ['技术方案', '核心优势', '主要局限', '应用范围']
    for i, header in enumerate(headers):
        hdr_cells[i].text = header
        set_cell_background(hdr_cells[i], 'B4C7E7')

    # 添加行
    solutions = existing.get('comparison', [
        {
            'name': '双筒式被动减振器',
            'advantage': '成熟可靠、成本低',
            'limitation': '阻尼特性固定、舒适性受限',
            'application': '主流乘用车'
        },
        {
            'name': 'CDC电控减振器',
            'advantage': '自适应调节、性能优异',
            'limitation': '成本高、系统复杂',
            'application': '豪华车和性能车'
        }
    ])

    for sol in solutions:
        row = comparison_table.add_row()
        row.cells[0].text = sol.get('name', '')
        row.cells[1].text = sol.get('advantage', '')
        row.cells[2].text = sol.get('limitation', '')
        row.cells[3].text = sol.get('application', '')

    doc.add_paragraph()
    doc.add_paragraph(existing.get('analysis_conclusion', '总的来说，现有技术虽然各有特点，但都存在一定的性能或成本限制。'))

    doc.add_page_break()

    # ===== 第三章：发明内容 =====
    add_heading_with_line(doc, '第三章  发明内容')

    invention = disclosure_data.get('invention', {})

    doc.add_heading('3.1  技术问题的定义', level=2)
    doc.add_paragraph(invention.get('problem_definition',
        disclosure_data.get('problem_description', '本发明针对现有减振器技术的主要瓶颈提出了新的解决方案。')))

    doc.add_heading('3.2  创新解决方案', level=2)
    doc.add_paragraph(invention.get('solution_overview',
        f"本发明的核心创新点包括：{', '.join(disclosure_data.get('innovation_points', []))}"))

    doc.add_heading('3.3  技术方案详细描述', level=2)
    doc.add_paragraph(invention.get('detailed_description',
        disclosure_data.get('technical_details', '技术方案详情如下。')))

    doc.add_heading('3.4  工作原理与特点', level=2)
    doc.add_paragraph(invention.get('working_principle',
        disclosure_data.get('working_principle', '本技术方案通过...工作原理，实现了...')))

    doc.add_page_break()

    # ===== 第四章：性能优势 =====
    add_heading_with_line(doc, '第四章  性能优势与效果')

    advantages = disclosure_data.get('advantages', {})

    doc.add_heading('4.1  相比现有技术的优势', level=2)
    adv_points = advantages.get('advantages', [])
    for point in adv_points:
        doc.add_paragraph(point, style='List Bullet')

    doc.add_heading('4.2  性能指标对比', level=2)

    # 性能指标表
    if advantages.get('performance_data'):
        perf_table = doc.add_table(rows=1, cols=3)
        perf_table.style = 'Light Grid Accent 1'
        hdr = perf_table.rows[0].cells
        hdr[0].text = '性能指标'
        hdr[1].text = '现有产品'
        hdr[2].text = '本发明'
        set_cell_background(hdr[0], 'B4C7E7')
        set_cell_background(hdr[1], 'B4C7E7')
        set_cell_background(hdr[2], 'B4C7E7')

        for metric, values in advantages.get('performance_data', {}).items():
            row = perf_table.add_row()
            row.cells[0].text = metric
            row.cells[1].text = str(values.get('existing', ''))
            row.cells[2].text = str(values.get('invented', ''))
    else:
        doc.add_paragraph('性能指标数据待补充（如有测试报告，请提供详细数据）。')

    doc.add_heading('4.3  经济效益与应用前景', level=2)
    doc.add_paragraph(advantages.get('market_prospect',
        disclosure_data.get('market_prospect', '本技术在成本、性能、可靠性等方面具有显著的市场竞争力。')))

    doc.add_page_break()

    # ===== 第五章：实施例 =====
    add_heading_with_line(doc, '第五章  实施例')

    implementations = disclosure_data.get('implementations', [])

    for idx, impl in enumerate(implementations, 1):
        doc.add_heading(f'5.{idx}  实施例{idx}', level=2)
        doc.add_paragraph(f"**应用场景：** {impl.get('scenario', '')}")
        doc.add_paragraph(f"**技术参数：** {impl.get('parameters', '')}")
        doc.add_paragraph(f"**试验结果：** {impl.get('test_results', '')}")

    if not implementations:
        doc.add_paragraph('实施例信息待补充。请提供具体的设计参数、样品信息和试验数据。')

    doc.add_page_break()

    # ===== 第六章：预期效果 =====
    add_heading_with_line(doc, '第六章  预期效果与前景')

    prospect = disclosure_data.get('prospect', {})

    doc.add_heading('6.1  技术的应用潜力', level=2)
    doc.add_paragraph(prospect.get('application_potential',
        disclosure_data.get('application_scenario', '本技术可广泛应用于各类乘用车、电动车等领域。')))

    doc.add_heading('6.2  预期的市场价值', level=2)
    doc.add_paragraph(prospect.get('market_value',
        '本发明可为企业带来显著的技术差异化优势，有望在市场中获得较好的竞争地位。'))

    doc.add_heading('6.3  后续开发方向', level=2)
    doc.add_paragraph(prospect.get('future_work',
        '后续可进一步优化性能、降低成本、扩展应用场景。'))

    # 页脚 - 保密声明
    doc.add_paragraph()
    doc.add_page_break()

    footer = doc.add_paragraph('【附注】本文件为机密文件，专供专利申报之用。未经授权，不得擅自复制、传播或用于其他目的。')
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in footer.runs:
        run.font.size = Pt(9)
        run.font.italic = True
        run.font.color.rgb = RGBColor(128, 128, 128)

    # 保存文档
    doc.save(output_path)
    print(f"✓ 交底书已生成：{output_path}")
    return output_path

if __name__ == '__main__':
    # 示例数据
    sample_data = {
        'title': '双棒式减振器的改进结构与阀系优化',
        'inventor': '张三',
        'tech_field': '汽车悬架系统',
        'file_number': '',
        'problem_description': '现有双筒式减振器在高频振动和低速大位移工况下的阻尼特性难以同时优化。',
        'innovation_points': ['新型节流阀结构', '双腔阀设计', '响应时间改进'],
        'technical_details': '通过优化补偿室和主腔的连接阀口设计，实现了低速大位移工况下的低阻尼和高频振动工况下的高阻尼的灵活组合。',
        'working_principle': '利用流体压力和流量的非线性变化特性...',
        'application_scenario': '中高端乘用车和电动车',
        'market_prospect': '预期可提高车辆舒适性15-20%，降低NVH指标2-3dB。'
    }

    output = generate_disclosure_document(sample_data, '/tmp/test_disclosure.docx')
