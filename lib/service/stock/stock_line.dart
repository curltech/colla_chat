import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

class StockLineService {
  dynamic send(String url, {dynamic data}) async {
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      String? httpConnectAddress = defaultPeerEndpoint.httpConnectAddress;
      if (httpConnectAddress != null) {
        DioHttpClient? client = httpClientPool.get(httpConnectAddress);
        Response<dynamic> response = await client.send(url, data);
        if (response.statusCode == 200) {
          return response.data;
        }
      }
    }
  }

  dynamic schedule() async {
    var data = await stockLineService.send('/processlog/Schedule');
    return data;
  }

  dynamic refreshTodayLine({int? startDate}) async {
    var data = await stockLineService.send('/dayline/RefreshTodayLine',
        data: startDate == null ? null : {'start_date': startDate});
    return data;
  }

  dynamic refreshMinLine() async {
    var data = await stockLineService.send('/minline/RefreshMinLine');
    return data;
  }

  dynamic refreshTodayMinLine() async {
    var data = await stockLineService.send('/minline/RefreshTodayMinLine');
    return data;
  }

  dynamic refreshQPerformance() async {
    var data = await stockLineService.send('/qperformance/RefreshQPerformance');
    return data;
  }

  dynamic refreshQStat() async {
    var data = await stockLineService.send('/qstat/RefreshQStat');
    return data;
  }

  dynamic refreshStatScore() async {
    var data = await stockLineService.send('/statscore/RefreshStatScore');
    return data;
  }

  dynamic createScorePercentile() async {
    var data = await stockLineService.send('/statscore/CreateScorePercentile');
    return data;
  }

  dynamic refreshStat({int? startDate}) async {
    var data = await stockLineService.send('/dayline/RefreshStat',
        data: startDate == null ? null : {'start_date': startDate});
    return data;
  }

  dynamic refreshBeforeMa({int? startDate}) async {
    var data = await stockLineService.send('/dayline/RefreshBeforeMa',
        data: startDate == null ? null : {'start_date': startDate});
    return data;
  }

  dynamic refreshEventCond() async {
    var data = await stockLineService.send('/eventcond/RefreshEventCond');
    return data;
  }

  dynamic updateShares() async {
    var data = await stockLineService.send('/share/UpdateShares');
    return data;
  }

  dynamic writeAllFile({int? startDate}) async {
    var data = await stockLineService.send('/dayline/WriteAllFile',
        data: startDate == null ? null : {'start_date': startDate});
    return data;
  }

  dynamic getUpdateForecast(String tsCode) async {
    var data = await stockLineService
        .send('/forecast/GetUpdateForecast', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateExpress(String tsCode) async {
    var data = await stockLineService
        .send('/express/GetUpdateExpress', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdatePerformance(String tsCode) async {
    var data = await stockLineService
        .send('/performance/GetUpdatePerformance', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateDayLine(String tsCode) async {
    var data = await stockLineService
        .send('/dayline/GetUpdateDayLine', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateTodayLine(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/GetUpdateTodayLine',
        data: {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic getUpdateMinLine(String tsCode) async {
    var data = await stockLineService
        .send('/minline/GetUpdateMinLine', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateTodayMinLine(String tsCode) async {
    var data = await stockLineService
        .send('/minline/GetUpdateTodayMinLine', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateWmqyLine(String tsCode) async {
    var data = await stockLineService
        .send('/wmqyline/GetUpdateWmqyLine', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateWmqyQPerformance(String tsCode) async {
    var data = await stockLineService.send(
        '/qperformance/GetUpdateWmqyQPerformance',
        data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateDayQPerformance(String tsCode) async {
    var data = await stockLineService.send(
        '/qperformance/GetUpdateDayQPerformance',
        data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateQStat(String tsCode) async {
    var data = await stockLineService
        .send('/qstat/GetUpdateQStat', data: {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateStatScore(String tsCode) async {
    var data = await stockLineService
        .send('/statscore/GetUpdateStatScore', data: {'ts_code': tsCode});
    return data;
  }

  dynamic updateStat(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/UpdateStat',
        data: {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic updateBeforeMa(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/UpdateBeforeMa',
        data: {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic getUpdateEventCond(String tsCode) async {
    var data = await stockLineService
        .send('/eventcond/GetUpdateEventCond', data: {'ts_code': tsCode});
    return data;
  }

  dynamic writeFile(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/WriteFile',
        data: {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }
}

final StockLineService stockLineService = StockLineService();
