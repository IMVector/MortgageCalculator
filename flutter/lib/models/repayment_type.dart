enum RepaymentType {
  equalPrincipalAndInterest('等额本息'),
  equalPrincipal('等额本金');

  final String label;
  const RepaymentType(this.label);
}
