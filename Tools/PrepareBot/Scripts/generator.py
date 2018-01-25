# -*- coding: utf-8 -*-
"""
    模拟生成一组身份证号码区域图片，用来训练神经网络。
"""

__author__ = 'gix'

import threading
import os
import shutil
import random
import sys
import getopt
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

opts, args = getopt.getopt(sys.argv[1:], "r:o:")

resource = "./resources"
output = "./generated"

for op, value in opts:
    if op == "-r":
        resource = value
    elif op == "-o":
        output = value
    else:
        print("非法参数")
        sys.exit()

COUNT = range(0, 500)
LABELS = '0123456789X'
BACKGROUND = resource + '/background.png'
FONT = resource + '/OCR-B 10 BT.ttf'


def start():
    """
    开始生成图片
    1. 清空输出目录
    2. 为了效率, 多线程加速生成
    """
    if os.path.exists(output):
        shutil.rmtree(output)
    os.mkdir(output)

    threads = []
    for idx in COUNT:
        threads.append(threading.Thread(target=create_image, args=([idx])))
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    print(LABELS)


def create_image(idx):
    """
    1. 读取 `resources` 目录下的背景图片和文字
    2. 把当前 `label` 画到背景上，并且做一些随机变化
    """
    o_image = Image.open(BACKGROUND)
    draw_brush = ImageDraw.Draw(o_image)

    font_size = random.randint(-5, 5) + 35
    draw_brush.text((10 + random.randint(-10, 10), 15 + random.randint(-2, 2)), LABELS,
                    fill='black',
                    font=ImageFont.truetype(FONT, font_size))

    o_image = ImageEnhance.Color(o_image).enhance(
        random.uniform(0.5, 1.5))  # 着色
    o_image = ImageEnhance.Brightness(o_image).enhance(
        random.uniform(0.5, 1.5))  # 亮度
    o_image = ImageEnhance.Contrast(o_image).enhance(
        random.uniform(0.5, 1.5))  # 对比度
    o_image = ImageEnhance.Sharpness(o_image).enhance(
        random.uniform(0.5, 1.5))  # 对比度
    o_image = o_image.rotate(random.randint(-2, 2))

    o_image.save(output + '/%d.png' % idx)


if __name__ == '__main__':
    start()
