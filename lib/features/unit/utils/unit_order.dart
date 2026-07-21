// PNL → LOT → M2 순으로 고정 (PNL이 모여 LOT가 되는 업무 규칙).
// 이 3개에 해당하지 않는 닉네임은 맨 뒤로 보낸다.
const _fixedUnitOrder = ['pnl', 'lot', 'm2'];

int fixedUnitRank(String label) {
  final index = _fixedUnitOrder.indexOf(label.trim().toLowerCase());
  return index == -1 ? _fixedUnitOrder.length : index;
}
