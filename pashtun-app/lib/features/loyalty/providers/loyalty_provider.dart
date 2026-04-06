import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLoyaltyPoints = 'loyalty_points';
const _pointsPerRupee = 0.01; // 1 point per ₹100 = 0.01 points/₹
const _pointsForReward = 500;
const _rewardValueInr = 50.0;

class LoyaltyState {
  final int points;
  final bool isLoading;

  const LoyaltyState({this.points = 0, this.isLoading = false});

  double get progressToNextReward =>
      (points % _pointsForReward) / _pointsForReward;

  int get pointsToNextReward =>
      _pointsForReward - (points % _pointsForReward);

  int get availableRewards => points ~/ _pointsForReward;

  double get totalRewardValue =>
      availableRewards * _rewardValueInr;

  LoyaltyState copyWith({int? points, bool? isLoading}) => LoyaltyState(
    points: points ?? this.points,
    isLoading: isLoading ?? this.isLoading,
  );
}

class LoyaltyNotifier extends Notifier<LoyaltyState> {
  @override
  LoyaltyState build() {
    Future.microtask(_loadPoints);
    return const LoyaltyState();
  }

  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_kLoyaltyPoints) ?? 0;
    state = LoyaltyState(points: points);
  }

  /// Called after a successful order to award points.
  /// 1 point per ₹100 spent.
  Future<void> awardPoints(double orderValueInr) async {
    final earned = (orderValueInr * _pointsPerRupee).round();
    if (earned <= 0) return;
    final newTotal = state.points + earned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLoyaltyPoints, newTotal);
    state = state.copyWith(points: newTotal);
  }

  /// Redeem points (e.g. 500 points = ₹50 coupon).
  Future<void> redeemPoints(int points) async {
    if (state.points < points) return;
    final newTotal = state.points - points;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLoyaltyPoints, newTotal);
    state = state.copyWith(points: newTotal);
    // TODO: trigger Shopify Admin API to create discount code
  }

  Future<int> fetchPoints(String customerId) async {
    // In production, fetch from Shopify customer metafields
    await _loadPoints();
    return state.points;
  }
}

final loyaltyProvider =
    NotifierProvider<LoyaltyNotifier, LoyaltyState>(LoyaltyNotifier.new);
