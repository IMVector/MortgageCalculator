enum PrepaymentType {
  shortenTerm('缩短期限'),
  reducePayment('减少月供');

  final String label;
  const PrepaymentType(this.label);
}
