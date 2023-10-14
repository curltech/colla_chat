import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

class StockLineService {
  dynamic send(String url, dynamic data) async {
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      String? httpConnectAddress = defaultPeerEndpoint.httpConnectAddress;
      if (httpConnectAddress != null) {
        DioHttpClient? client = httpClientPool.get(httpConnectAddress);
        if (client != null) {
          Response<dynamic> response = await client.send(url, data);
          if (response.statusCode == 200) {
            return response.data;
          }
        }
      }
    }
  }

  dynamic schedule(int startDate) async {
    var data = await stockLineService
        .send('/processlog/Schedule', {'start_date': startDate});
    return data;
  }

  dynamic refreshTodayLine(int startDate) async {
    var data = await stockLineService
        .send('/dayline/RefreshTodayLine', {'start_date': startDate});
    return data;
  }

  dynamic refreshMinLine(int startDate) async {
    var data = await stockLineService
        .send('/minline/RefreshMinLine', {'start_date': startDate});
    return data;
  }

  dynamic refreshTodayMinLine(int startDate) async {
    var data = await stockLineService
        .send('/minline/RefreshTodayMinLine', {'start_date': startDate});
    return data;
  }

  dynamic refreshQPerformance(int startDate) async {
    var data = await stockLineService
        .send('/qperformance/RefreshQPerformance', {'start_date': startDate});
    return data;
  }

  dynamic refreshQStat(int startDate) async {
    var data = await stockLineService
        .send('/qstat/RefreshQStat', {'start_date': startDate});
    return data;
  }

  dynamic refreshStatScore(int startDate) async {
    var data = await stockLineService
        .send('/statscore/RefreshStatScore', {'start_date': startDate});
    return data;
  }

  dynamic createScorePercentile(int startDate) async {
    var data = await stockLineService
        .send('/statscore/CreateScorePercentile', {'start_date': startDate});
    return data;
  }

  dynamic refreshStat(int startDate) async {
    var data = await stockLineService
        .send('/dayline/RefreshStat', {'start_date': startDate});
    return data;
  }

  dynamic refreshBeforeMa(int startDate) async {
    var data = await stockLineService
        .send('/dayline/RefreshBeforeMa', {'start_date': startDate});
    return data;
  }

  dynamic refreshEventCond(int startDate) async {
    var data = await stockLineService
        .send('/eventcond/RefreshEventCond', {'start_date': startDate});
    return data;
  }

  dynamic updateShares(int startDate) async {
    var data = await stockLineService
        .send('/share/UpdateShares', {'start_date': startDate});
    return data;
  }

  dynamic writeAllFile(int startDate) async {
    var data = await stockLineService
        .send('/dayline/WriteAllFile', {'start_date': startDate});
    return data;
  }

  dynamic getUpdateForecast(String tsCode) async {
    var data = await stockLineService
        .send('/forecast/GetUpdateForecast', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateExpress(String tsCode) async {
    var data = await stockLineService
        .send('/express/GetUpdateExpress', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdatePerformance(String tsCode) async {
    var data = await stockLineService
        .send('/performance/GetUpdatePerformance', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateDayLine(String tsCode) async {
    var data = await stockLineService
        .send('/dayline/GetUpdateDayLine', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateTodayLine(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/GetUpdateTodayLine',
        {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic getUpdateMinLine(String tsCode) async {
    var data = await stockLineService
        .send('/minline/GetUpdateMinLine', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateTodayMinLine(String tsCode) async {
    var data = await stockLineService
        .send('/minline/GetUpdateTodayMinLine', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateWmqyLine(String tsCode) async {
    var data = await stockLineService
        .send('/wmqyline/GetUpdateWmqyLine', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateWmqyQPerformance(String tsCode) async {
    var data = await stockLineService
        .send('/qperformance/GetUpdateWmqyQPerformance', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateDayQPerformance(String tsCode) async {
    var data = await stockLineService
        .send('/qperformance/GetUpdateDayQPerformance', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateQStat(String tsCode) async {
    var data = await stockLineService
        .send('/qstat/GetUpdateQStat', {'ts_code': tsCode});
    return data;
  }

  dynamic getUpdateStatScore(String tsCode) async {
    var data = await stockLineService
        .send('/statscore/GetUpdateStatScore', {'ts_code': tsCode});
    return data;
  }

  dynamic updateStat(String tsCode, int startDate) async {
    var data = await stockLineService.send(
        '/dayline/UpdateStat', {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic updateBeforeMa(String tsCode, int startDate) async {
    var data = await stockLineService.send('/dayline/UpdateBeforeMa',
        {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }

  dynamic getUpdateEventCond(String tsCode) async {
    var data = await stockLineService
        .send('/eventcond/GetUpdateEventCond', {'ts_code': tsCode});
    return data;
  }

  dynamic writeFile(String tsCode, int startDate) async {
    var data = await stockLineService.send(
        '/dayline/WriteFile', {'ts_code': tsCode, 'start_date': startDate});
    return data;
  }
}

final StockLineService stockLineService = StockLineService();
