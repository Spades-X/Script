// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: pink; icon-glyph: paper-plane;

// 添加require，是为了vscode中可以正确引入包，以获得自动补全等功能
if (typeof require === 'undefined') require = importModule;
const {DmYY, Runing} = require('./DmYY');

// @组件代码开始
class Widget extends DmYY {
  constructor(arg) {
    super(arg);
    this.name = '中国电信';
    this.en = 'ChinaTelecom';
    this.Run();
  }

  cookie = 'CZSSON=493ade8b7788b357a5399a0c51fd6bd1b3d2479b87755fa54149c48e62d321799f3e914604f264c24af8f6fc38c48ce924c6d1dd20d0353a61b21892ebbb63f468903cad6beec8b158443a8781e8ab5ca7c2a61f7d8bd1b7e446158df71b385458784ce466dcbc20ed2582d5c43d430b971824fc24d5583fb9efe8759b530b0575960c97149fe8bb0a1bc556f3702366966b0e3a151f23de677d52973d9611790a6b3ef7f3cad686e79f64a3a392e961bed357140897bf888866ed98af20f5e6c6592bc23b60ab90d97610f35059efcd9b42c3234baf2ab4888fb253579f7cda243d32c3ad77ba219b59a11bc1927f19227ef5ec8b2b2839; SSON=493ade8b7788b357a5399a0c51fd6bd1b3d2479b87755fa54149c48e62d321799f3e914604f264c24af8f6fc38c48ce924c6d1dd20d0353a61b21892ebbb63f468903cad6beec8b158443a8781e8ab5ca7c2a61f7d8bd1b7e446158df71b385458784ce466dcbc20ed2582d5c43d430b971824fc24d5583fb9efe8759b530b0575960c97149fe8bb0a1bc556f3702366966b0e3a151f23de677d52973d9611790a6b3ef7f3cad686e79f64a3a392e961bed357140897bf888866ed98af20f5e6c6592bc23b60ab90d97610f35059efcd9b42c3234baf2ab4888fb253579f7cda243d32c3ad77ba219b59a11bc1927f19227ef5ec8b2b2839; JSESSIONID=aaaaInINN-21z4IXVnuFx; RZSSON=5331c3255b8b68c9216d47a19e7786012fa2afe378775596d6d6adb1460a91eff78cf73494233cbb6828518b14016144d517161160730268; GRAYNUMBER=BC31BD2364D861F1339A292FE6228109; 189LOGINFLAG=newwebmail; s_fid=341CFA9B7E2956B8-3ECE244B3968250E; lvid=52bc89b9847195e32fb86eb89492b7f5; nvid=1; svid=9124259F02CB3DF92F4952CCD03A8A8A; GUID=b6538aa08293459cb8136f2c2214a6b9; apm_ct=20210301205021302; apm_ip=75C988216DAFFEFEC1475C3DB71FFF4F; apm_ua=7953488AFAFAC5348C940A9B41B99605; apm_uid=2BE828E35C86936A29C555D35876ABF7';
  authToken = '5331c3255b8b68c976add7d7029abcf3a18ac31d516acdb7189d4c17b6e8aa35af1b9236189453e5c45f6815e1936a08';
  fgCircleColor = Color.dynamic(new Color('#dddef3'), new Color('#fff'));
  percentColor = this.widgetColor;
  textColor1 = Color.dynamic(new Color('#333'), new Color('#fff'));
  textColor2 = this.widgetColor;

  circleColor1 = new Color('#ffbb73');
  circleColor2 = new Color('#ff0029');
  circleColor3 = new Color('#00b800');
  circleColor4 = new Color('#8376f9');
  iconColor = new Color('#827af1');

  format = (str) => {
    return parseInt(str) >= 10 ? str : `0${str}`;
  };

  date = new Date();
  arrUpdateTime = [
    this.format(this.date.getMonth() + 1),
    this.format(this.date.getDate()),
    this.format(this.date.getHours()),
    this.format(this.date.getMinutes()),
  ];

  // percent 的计算方式，剩余/总量 * 100 = 百分比| 百分比 * 3.6 ，为显示进度。
  phoneBill = {
    percent: 0,
    label: '话费剩余',
    count: 0,
    unit: '元',
    icon: 'yensign.circle',
    circleColor: this.circleColor1,
  };

  flow = {
    percent: 0,
    label: '流量剩余',
    count: 0,
    unit: 'M',
    icon: 'waveform.path.badge.minus',
    circleColor: this.circleColor2,
  };

  voice = {
    percent: 0,
    label: '语音剩余',
    count: 0,
    unit: '分钟',
    icon: 'mic',
    circleColor: this.circleColor3,
  };

  updateTime = {
    percent: 0,
    label: '电信更新',
    count: `${this.arrUpdateTime[2]}:${this.arrUpdateTime[3]}`,
    unit: '',
    urlIcon: 'https://raw.githubusercontent.com/Orz-3/mini/master/10000.png',
    circleColor: this.circleColor4,
  };

  canvSize = 100;
  canvWidth = 5; // circle thickness
  canvRadius = 100; // circle radius
  dayRadiusOffset = 60;
  canvTextSize = 40;

  options = {
    headers: {
      // type: "alipayMiniApp",
      // "User-Agent": "TYUserCenter/2.8 (iPhone; iOS 14.0; Scale/3.00)",
    },
    // body: "t=tysuit",
    method: 'POST',
  };

  fetchUri = {
    detail: 'https://e.189.cn/store/user/package_detail.do',
    balance: 'https://e.189.cn/store/user/balance_new.do',
  };

  init = async () => {
    try {
      const nowHours = this.date.getHours();
      const updateHours = nowHours > 12 ? 24 : 12;
      this.updateTime.percent = Math.floor((nowHours / updateHours) * 100);
      await this.getData();
    } catch (e) {
      console.log(e);
    }
  };

  // MB 和 GB 自动转换
  formatFlow(number) {
    const n = number / 1024;
    if (n < 1024) {
      return {count: n.toFixed(2), unit: 'M'};
    }
    return {count: (n / 1024).toFixed(2), unit: 'G'};
  }

  getData = async () => {
    const detail = await this.http({
      url: this.fetchUri.detail,
      ...this.options,
    });
    console.log(detail);
    const balance = await this.http({
      url: this.fetchUri.balance,
      ...this.options,
    });

    if (detail.result === 0) {
      // 套餐分钟数
      this.voice.percent = Math.floor(
          (parseInt(detail.voiceBalance) / parseInt(detail.voiceAmount)) * 100,
      );
      this.voice.count = detail.voiceBalance;
      console.log(detail.items);
      if (!detail.count && !detail.total) {
        detail.items.forEach((data) => {
          if (data.offerType !== 19) {
            data.items.forEach((item) => {
              if (item.unitTypeId === '3') {
                if (item.usageAmount !== '0' && item.balanceAmount !== '0') {
                  this.flow.percent = Math.floor(
                      (item.balanceAmount / (item.ratableAmount || 1)) * 100,
                  );
                  const flow = this.formatFlow(item.balanceAmount);
                  this.flow.count = flow.count;
                  this.flow.unit = flow.unit;
                  this.flow.max = item.ratableAmount;
                }
              }
            });
          }
        });
      } else {
        this.flow.percent = Math.floor(
            (detail.balance / (detail.total || 1)) * 100,
        );
        const flow = this.formatFlow(detail.balance);
        this.flow.count = flow.count;
        this.flow.unit = flow.unit;
        this.flow.max = detail.total;
      }

    }
    if (balance.result === 0) {
      // 余额
      this.phoneBill.count = parseFloat(
          parseInt(balance.totalBalanceAvailable) / 100).toFixed(2)
    }
    this.phoneBill.percent = Math.floor((this.phoneBill.count / 100) * 100);
  };

  makeCanvas() {
    const canvas = new DrawContext();
    canvas.opaque = false;
    canvas.respectScreenScale = true;
    canvas.size = new Size(this.canvSize, this.canvSize);
    return canvas;
  }

  makeCircle(canvas, radiusOffset, degree, color) {
    let ctr = new Point(this.canvSize / 2, this.canvSize / 2);
    // Outer circle
    const bgx = ctr.x - (this.canvRadius - radiusOffset);
    const bgy = ctr.y - (this.canvRadius - radiusOffset);
    const bgd = 2 * (this.canvRadius - radiusOffset);
    const bgr = new Rect(bgx, bgy, bgd, bgd);
    canvas.setStrokeColor(this.fgCircleColor);
    canvas.setLineWidth(2);
    canvas.strokeEllipse(bgr);
    // Inner circle
    canvas.setFillColor(color);
    for (let t = 0; t < degree; t++) {
      const rect_x =
          ctr.x +
          (this.canvRadius - radiusOffset) * this.sinDeg(t) -
          this.canvWidth / 2;
      const rect_y =
          ctr.y -
          (this.canvRadius - radiusOffset) * this.cosDeg(t) -
          this.canvWidth / 2;
      const rect_r = new Rect(rect_x, rect_y, this.canvWidth, this.canvWidth);
      canvas.fillEllipse(rect_r);
    }
  }

  drawText(txt, canvas, txtOffset, fontSize) {
    const txtRect = new Rect(
        this.canvTextSize / 2 - 20,
        txtOffset - this.canvTextSize / 2,
        this.canvSize,
        this.canvTextSize,
    );
    canvas.setTextColor(this.percentColor);
    canvas.setFont(Font.boldSystemFont(fontSize));
    canvas.setTextAlignedCenter();
    canvas.drawTextInRect(`${txt}`, txtRect);
  }

  drawPointText(txt, canvas, txtPoint, fontSize) {
    canvas.setTextColor(this.percentColor);
    canvas.setFont(Font.boldSystemFont(fontSize));
    canvas.drawText(txt, txtPoint);
  }

  sinDeg(deg) {
    return Math.sin((deg * Math.PI) / 180);
  }

  cosDeg(deg) {
    return Math.cos((deg * Math.PI) / 180);
  }

  setCircleText = (stack, data) => {
    const stackCircle = stack.addStack();
    const canvas = this.makeCanvas();
    stackCircle.size = new Size(70, 70);
    this.makeCircle(
        canvas,
        this.dayRadiusOffset,
        data.percent * 3.6,
        data.circleColor,
    );

    this.drawText(data.percent, canvas, 75, 18);
    this.drawPointText(`%`, canvas, new Point(65, 50), 14);
    stackCircle.backgroundImage = canvas.getImage();

    stackCircle.setPadding(20, 0, 0, 0);
    stackCircle.addSpacer();
    const icon = data.urlIcon
        ? {image: data.icon}
        : SFSymbol.named(data.icon);
    const imageIcon = stackCircle.addImage(icon.image);
    imageIcon.tintColor = this.iconColor;
    imageIcon.imageSize = new Size(15, 15);
    // canvas.drawImageInRect(icon.image, new Rect(110, 80, 60, 60));
    stackCircle.addSpacer();

    stack.addSpacer(5);
    const stackDesc = stack.addStack();
    stackDesc.size = new Size(70, 60);
    stackDesc.centerAlignContent();
    stackDesc.layoutVertically();
    stackDesc.addSpacer(10);
    const textLabel = this.textFormat.defaultText;
    textLabel.size = 12;
    textLabel.color = this.textColor2;
    this.provideText(data.label, stackDesc, textLabel);
    stackDesc.addSpacer(10);

    const stackDescFooter = stackDesc.addStack();
    stackDescFooter.centerAlignContent();
    const textCount = this.textFormat.title;
    textCount.size = 16;
    textCount.color = this.textColor1;
    this.provideText(`${data.count}`, stackDescFooter, textCount);
    stackDescFooter.addSpacer(2);
    this.provideText(data.unit, stackDescFooter, textLabel);
  };

  renderSmall = async (w) => {
    w.setPadding(5, 5, 5, 5);
    const stackBody = w.addStack();
    stackBody.layoutVertically();
    const stackTop = stackBody.addStack();
    this.setCircleText(stackTop, this.phoneBill);
    const stackBottom = stackBody.addStack();
    this.setCircleText(stackBottom, this.flow);

    const stackFooter = stackBody.addStack();
    stackFooter.addSpacer();
    const text = this.textFormat.defaultText;
    text.color = new Color('#aaa');
    this.provideText(
        `电信更新：${this.arrUpdateTime[2]}:${this.arrUpdateTime[3]}`,
        stackFooter,
        text,
    );
    stackFooter.addSpacer();
    return w;
  };

  renderMedium = async (w) => {
    const stackBody = w.addStack();
    stackBody.layoutVertically();
    const stackTop = stackBody.addStack();
    this.setCircleText(stackTop, this.phoneBill);
    this.setCircleText(stackTop, this.flow);
    const stackBottom = stackBody.addStack();
    this.setCircleText(stackBottom, this.voice);
    this.updateTime.icon = await this.$request.get(
        this.updateTime.urlIcon,
        'IMG',
    );
    this.setCircleText(stackBottom, this.updateTime);
    return w;
  };

  renderLarge = async (w) => {
    return await this.renderMedium(w);
  };

  renderWebView = async () => {
    const webView = new WebView();
    const url = 'https://e.189.cn/index.do';
    await webView.loadURL(url);
    await webView.present(false);

    const request = new Request(this.fetchUri.detail);
    request.method = 'POST';
    const response = await request.loadJSON();
    console.log(response);
    if (response.result === -10001) {
      const index = await this.generateAlert('未获取到用户信息', [
        '取消',
        '重试',
      ]);
      if (index === 0) return;
      await this.renderWebView();
    } else {
      const cookies = request.response.cookies;
      let cookie = [];
      cookie = cookies.map((item) => `${item.name}=${item.value}`);
      cookie = cookie.join('; ');
      this.settings.cookie = cookie;
      this.saveSettings();
    }
  };

  Run() {
    if (config.runsInApp) {
      const widgetInitConfig = {cookie: 'china_telecom_cookie'};
      this.registerAction('颜色配置', async () => {
        await this.setAlertInput(
            `${this.name}颜色配置`,
            '进度条颜色|底圈颜色\n图标颜色|比值颜色|值颜色',
            {
              step1: '进度颜色 1',
              step2: '进度颜色 2',
              step3: '进度颜色 3',
              step4: '进度颜色 4',
              inner: '底圈颜色',
              icon: '图标颜色',
              percent: '比值颜色',
              value: '值颜色',
            },
        );
      });
      this.registerAction('账号设置', async () => {
        const index = await this.generateAlert('设置账号信息', [
          '取消',
          '网站登录',
        ]);
        if (index === 0) return;
        await this.renderWebView();
      });
      this.registerAction('代理缓存', async () => {
        await this.setCacheBoxJSData(widgetInitConfig);
      });
      this.registerAction('基础设置', this.setWidgetConfig);
    }
    const {
      step1,
      step2,
      step3,
      step4,
      inner,
      icon,
      percent,
      value,
      // authToken,
      cookie,
    } = this.settings;
    this.fgCircleColor = inner ? new Color(inner) : this.fgCircleColor;
    this.textColor1 = value ? new Color(value) : this.textColor1;
    this.phoneBill.circleColor = step1 ? new Color(step1) : this.circleColor1;
    this.flow.circleColor = step2 ? new Color(step2) : this.circleColor2;
    this.voice.circleColor = step3 ? new Color(step3) : this.circleColor3;
    this.updateTime.circleColor = step4 ? new Color(step4) : this.circleColor4;

    this.iconColor = icon ? new Color(icon) : this.iconColor;
    this.percentColor = percent ? new Color(percent) : this.percentColor;

    this.cookie = cookie;
    if (this.cookie) this.options.headers.cookie = this.cookie;
    // this.authToken = authToken;
    // if (this.authToken) this.options.headers.authToken = this.authToken;
  }

  /**
   * 渲染函数，函数名固定
   * 可以根据 this.widgetFamily 来判断小组件尺寸，以返回不同大小的内容
   */
  async render() {
    await this.init();
    const widget = new ListWidget();
    widget.setPadding(0, 0, 0, 0);
    await this.getWidgetBackgroundImage(widget);
    if (this.widgetFamily === 'medium') {
      return await this.renderMedium(widget);
    } else if (this.widgetFamily === 'large') {
      return await this.renderLarge(widget);
    } else {
      return await this.renderSmall(widget);
    }
  }
}

// @组件代码结束
// await Runing(Widget, "", false); // 正式环境
await Runing(Widget, args.widgetParameter, false); //远程开发环境
