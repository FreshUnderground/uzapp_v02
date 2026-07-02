class PwaInstallInfo {
  final bool shouldShow;
  final bool isIos;

  const PwaInstallInfo({
    required this.shouldShow,
    required this.isIos,
  });
}

class PwaInstallService {
  static PwaInstallInfo getInstallInfo() {
    return const PwaInstallInfo(shouldShow: false, isIos: false);
  }
}
