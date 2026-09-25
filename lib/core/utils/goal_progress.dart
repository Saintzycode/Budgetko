/// Progress towards a savings goal, clamped to 0..1.
///
/// Guards the two ways a bad value can reach this: a zero or non-finite
/// target (which would otherwise make `0 / 0` produce NaN), and a
/// non-finite current amount. Callers multiply this by 100 and call
/// `round()`, which throws `UnsupportedError` on NaN — so returning 0 is
/// the safe degradation for unusable data.
double goalProgress(double currentAmount, double targetAmount) {
  if (targetAmount <= 0 || !targetAmount.isFinite) return 0;
  final raw = currentAmount / targetAmount;
  if (!raw.isFinite) return 0;
  return raw.clamp(0.0, 1.0).toDouble();
}
