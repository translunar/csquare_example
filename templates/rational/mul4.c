inline TYPE mul(INT anum, INT aden, INT bnum, INT bden) {
  TYPE result;

  INT g1 = gcf(anum, bden);
  INT g2 = gcf(aden, bnum);

  result.n = (anum / g1) * (bnum / g2);
  result.d = (aden / g2) * (bden / g1);

  return result;
}
