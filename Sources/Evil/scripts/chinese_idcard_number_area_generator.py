# -*- coding: utf-8 -*-
'''
    模拟生成一组身份证号码区域图片，用来训练神经网络。
'''
import threading
import os
import shutil
import random
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

COUNT = range(0, 500)
OUT_PATH = './generatedNumberAreaImages'
LABELS = '0123456789X'


def start():
    '''
    开始生成图片
    1. 清空输出目录
    2. 为了效率, 多线程加速生成
    '''
    if os.path.exists(OUT_PATH):
        shutil.rmtree(OUT_PATH)
    os.mkdir(OUT_PATH)

    for idx in COUNT:
        new_thread = threading.Thread(target=create_image, args=([idx]))
        new_thread.start()


def create_image(idx):
    '''
    1. 读取 `resources` 目录下的背景图片和文字
    2. 把当前 `label` 画到背景上，并且做一些随机变化
    '''
    o_image = Image.open('./resources/background.png')
    draw_brush = ImageDraw.Draw(o_image)

    font_size = random.randint(-5, 5) + 35
    draw_brush.text((10 + random.randint(-10, 10), 15 + random.randint(-2, 2)), LABELS,
                    fill='black',
                    font=ImageFont.truetype('./resources/OCR-B 10 BT.ttf', font_size))

    o_image = ImageEnhance.Color(o_image).enhance(
        random.uniform(0.5, 1.5))  # 着色
    o_image = ImageEnhance.Brightness(o_image).enhance(
        random.uniform(0.5, 1.5))  # 亮度
    o_image = ImageEnhance.Contrast(o_image).enhance(
        random.uniform(0.5, 1.5))  # 对比度
    o_image = ImageEnhance.Sharpness(o_image).enhance(
        random.uniform(0.5, 1.5))  # 对比度
    o_image = o_image.rotate(random.randint(-2, 2))

    o_image.save(OUT_PATH + '/%d.png' % idx)


if __name__ == '__main__':
    start()
