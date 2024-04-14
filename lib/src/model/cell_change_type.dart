// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// CellChangeType includes the following Cell changes Types
///
/// add - when a cell is added to a sheet
/// update - when the cell is update
/// delete - when the cell is remove
/// referenceAdd - when a new reference is Added to a cell
/// referenceUpdate - when the references are updated
/// referenceDelete - when references to a cell are deleted
enum CellChangeType {
  add,
  update,
  delete,
  referenceAdd,
  referenceUpdate,
  referenceDelete,
}
