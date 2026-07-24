# Formula.Firewall 해결 및 로드 방식 안내

## 현재 오류의 원인

오류가 표시된 단계는 `dimOrganisation`의 `UniqueCodes`이지만,
`Table.Distinct` 자체가 원인은 아닙니다.

기존 구조는 다음 두 작업을 한 평가 파티션에서 수행했습니다.

1. `pReferenceFolder`가 `fnGetParameter`를 통해
   `Excel.CurrentWorkbook`의 값을 참조
2. `dimOrganisation`이 그 값을 `File.Contents`의 파일 경로로 사용

Power Query 개인정보 방화벽은 다른 쿼리를 참조하면서 동시에 파일
데이터 원본에 직접 접근하는 구조를 차단할 수 있습니다.

개인정보 보호 기능을 끄지 않고 해결하기 위해 폴더와 날짜 값 여섯 개를
정식 Power Query 매개변수로 변경했습니다.

## 지금 Excel에서 할 작업

이미 생성한 다음 여섯 항목의 Advanced Editor 내용만 교체하세요.

| Excel의 항목 | 붙여넣을 최신 파일 |
|---|---|
| `pWorkforceFolder` | `01_pWorkforceFolder.pq` |
| `pAbsenceFolder` | `02_pAbsenceFolder.pq` |
| `pActivityFolder` | `03_pActivityFolder.pq` |
| `pReportingStartMonth` | `04_pReportingStartMonth.pq` |
| `pReportingEndMonth` | `05_pReportingEndMonth.pq` |
| `pReferenceFolder` | `06_pReferenceFolder.pq` |

각 항목에서:

1. Power Query 편집기의 왼쪽 목록에서 항목을 선택합니다.
2. **홈 → 고급 편집기**를 선택합니다.
3. 기존 내용을 전부 지웁니다.
4. 표에 표시된 최신 `.pq` 파일 내용을 전부 붙여넣습니다.
5. **완료**를 선택합니다.
6. 값 하나를 표시하는 매개변수 아이콘으로 바뀌었는지 확인합니다.
7. 일반 쿼리로 남아 있으면 마우스 오른쪽 버튼을 누르고
   **매개 변수로 변환**을 선택합니다.

여섯 개를 모두 교체한 다음:

1. `dimOrganisation`을 선택합니다.
2. **미리 보기 새로 고침**을 실행합니다.
3. 148행이 표시되고 오류가 사라졌는지 확인합니다.
4. 정상이라면 쿼리 18번부터 계속 등록합니다.

`fnGetParameter`는 삭제하지 않아도 됩니다. Excel 표 기반 값의 구조를
보여주는 문서화용 helper로 연결만 유지합니다.

## 경로나 기간을 나중에 변경하는 방법

실제 실행 값은 Power Query 편집기에서
**홈 → 매개 변수 관리**를 선택하여 변경합니다.

관리자가 확인할 수 있도록 `Parameters` 워크시트의 `tblParameters`에도
동일한 값을 기록하세요. 워크시트 표는 통제 기록이고, Power Query
매개변수가 실제 실행 값입니다.

## 로드 방식도 동일하게 진행하는가?

쿼리를 만들고 Advanced Editor에 코드를 붙여넣는 과정은 동일합니다.
마지막 **로드 위치만** 다르게 선택합니다.

| 안내 표시 | Excel에서 선택할 항목 |
|---|---|
| 연결만 만들기 | **연결만 만들기** |
| 워크시트 표 | **표 → 새 워크시트** |
| 데이터 모델 | **연결만 만들기** + **이 데이터를 데이터 모델에 추가** |

권장 설정은 다음과 같습니다.

### `dimOrganisation`

- **표 → 새 워크시트**
- **이 데이터를 데이터 모델에 추가**도 체크

148행뿐이므로 워크시트에서 직접 검토할 수 있고, 데이터 모델에서는
세 Fact 테이블의 조직 차원으로 사용할 수 있습니다.

### Clean Fact 쿼리 세 개

- `qryWorkforceClean`
- `qryAbsenceClean`
- `qryServiceActivityClean`

다음처럼 설정합니다.

- **연결만 만들기**
- **이 데이터를 데이터 모델에 추가** 체크

이 세 쿼리는 PivotTable 및 이후 모델 관계에 사용합니다. 중간 결과를
워크시트에 모두 펼칠 필요는 없습니다.

### 워크시트 표 쿼리

- `qryPowerQueryExceptions`
- `qryPowerQueryRefreshSummary`
- `qrySourceFileRegister`
- `qryDataQualityRuleResults`
- `qryDataQualityReconciliation`

다음처럼 설정합니다.

- **표**
- **새 워크시트**
- 데이터 모델 추가는 선택하지 않음

이 결과들은 관리자가 직접 검토하고 CSV로 저장하기 위한 통제
출력입니다.

## 사용하지 않을 해결 방법

Excel의 개인정보 보호 수준을 항상 무시하도록 설정하면 오류가 사라질
수 있지만, 데이터 보호 통제를 무력화하므로 이 프로젝트에서는 사용하지
않습니다.

정식 매개변수 교체 후에도 오류가 남으면 다음 두 화면을 캡처하여
제공하세요.

1. 왼쪽 쿼리 목록에서 여섯 매개변수의 아이콘이 보이는 화면
2. `dimOrganisation`의 전체 오류 메시지와 적용된 단계 화면

## 다음 단계에서 `Size` 열 오류가 발생하는 경우

다음 오류는 `stgWorkforceFiles`, `stgAbsenceFiles` 또는
`stgServiceFiles`가 `fnGetSourceFiles`를 호출할 때 발생할 수 있습니다.

> Expression.Error: The column 'Size' of the table wasn't found.

일부 Excel Power Query 환경에서는 `Folder.Files` 결과에 파일 크기가
최상위 `Size` 열로 제공되지 않고 `Attributes` 레코드 안에 들어갑니다.
최신 `15_fnGetSourceFiles.pq`는 다음 순서로 파일 크기를 계산합니다.

1. `Attributes[Size]`가 있으면 사용
2. 없으면 `Binary.Length([Content])`로 실제 바이너리 길이 계산

Excel에서 할 작업:

1. `fnGetSourceFiles`를 선택합니다.
2. **홈 → 고급 편집기**를 엽니다.
3. 기존 내용을 전부 지웁니다.
4. 최신 `15_fnGetSourceFiles.pq` 전체 내용을 붙여넣습니다.
5. **완료**를 선택합니다.
6. 먼저 `stgWorkforceFiles`의 미리 보기를 새로고침합니다.
7. 정상이라면 `stgAbsenceFiles`, `stgServiceFiles`도 새로고침합니다.

18번 이후 쿼리를 삭제하거나 다시 만들 필요는 없습니다.

## `OrganisationMappingStatus` 필드 오류

다음 오류가 발생하면 60–62번 classified 쿼리를 최신 내용으로
교체합니다.

> Expression.Error: The field 'OrganisationMappingStatus' of the record
> wasn't found.

수정 대상:

- `dqWorkforceClassified` ← `60_dqWorkforceClassified.pq`
- `dqAbsenceClassified` ← `61_dqAbsenceClassified.pq`
- `dqServiceActivityClassified` ← `62_dqServiceActivityClassified.pq`

각 쿼리의 **Advanced Editor**에서 기존 내용을 전체 삭제하고 최신 파일
내용을 붙여넣습니다. 세 쿼리는 모두 **Only Create Connection**으로
유지합니다.

교체 후 다음 순서로 미리보기를 새로고침합니다.

1. `dqWorkforceClassified`
2. `dqAbsenceClassified`
3. `dqServiceActivityClassified`

세 쿼리가 정상으로 표시되면 24번부터 계속 진행합니다.
